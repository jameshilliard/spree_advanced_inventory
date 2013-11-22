require 'spec_helper'

describe Spree::Order do
  let(:order) { stub_model(Spree::Order) }
  let(:inventory_unit) { stub_model(Spree::InventoryUnit) }
  let(:inventory2) { stub_model(Spree::InventoryUnit) }
  let(:payment1) { stub_model(Spree::Payment) }
  let(:payment2) { stub_model(Spree::Payment) }
  let(:payment3) { stub_model(Spree::Payment) }
  let(:payment4) { stub_model(Spree::Payment) }
  let(:shipping_method) { mock_model Spree::ShippingMethod, :calculator => mock('calculator'), :adjustment_label => "Shipping" }
  let(:shipment) do
    shipment = Spree::Shipment.new :order => order, :shipping_method => shipping_method
    shipment.state = 'pending'
    shipment
  end  

  before :each do
    @variant1 = mock_model(Spree::Variant, 
                           :product => "product1", 
                           on_hand: 0, 
                           count_on_hand: 0)

    @line_items = [mock_model(Spree::LineItem, 
                              :variant => @variant1, 
                              :variant_id => @variant1.id, 
                              :quantity => 1)]


    inventory_unit.stub(:variant_id => @variant1.id)
    inventory_unit.stub(:order_id => order.id)
    inventory_unit.stub(:save => true)

    order.stub(:line_items => @line_items)
    order.stub(:inventory_units => [inventory_unit])
    order.stub(:variant_inventory_units => [inventory_unit])
    
    payment1.stub(:state).and_return("pending")
    payment1.stub(:source_type).and_return("Spree::CreditCard")
    payment1.stub(:amount).and_return(10.50)
   
    payment2.stub(:state).and_return("checkout")
    payment2.stub(:source_type).and_return(nil)
    payment2.stub(:amount).and_return(5.25)
    
    payment3.stub(:state).and_return("paid")
    payment3.stub(:source_type).and_return("Spree::CreditCard")
    payment3.stub(:amount).and_return(6.25)

    payment4.stub(:state).and_return("paid")
    payment4.stub(:source_type).and_return(nil)
    payment4.stub(:amount).and_return(7.25)

    order.stub(:payments).and_return([payment1, payment2, payment3, payment4])      
  end

  context "#dropship_conversion" do

    context "a new dropship" do
      before do
        order.is_dropship = true
        order.stub(:is_dropship_was => false)
        order.inventory_adjusted = false
      end

      it "should call make_dropship" do
        order.should_receive(:make_dropship)
        order.dropship_conversion
      end

    end

    context "dropship -> non-dropship" do
      before :each do
        order.is_dropship = false
        order.stub(:is_dropship_was => true)
      end

      it "should call make_regular" do
        order.should_receive(:make_regular)
        order.dropship_conversion
      end
    end

    context "non-dropship -> dropship" do
      before :each do
        order.is_dropship = true
      end

      it "should call make_dropship" do
        order.should_receive(:make_dropship)
        order.dropship_conversion
      end
    end
  end

  context "#make_dropship" do
    before :each do
      order.is_dropship = true
      order.stub(:is_dropship_was => false)
    end

    context "with inventory adjustments" do
      before do
        order.inventory_adjusted = true
      end

      it "should increase variant stock, update inventory units and remove inventory adjusted flag" do
        order.should_receive(:adjust_variant_stock).
          with(@line_items.first.variant, @line_items.first.quantity)

        order.should_receive(:update_inventory_unit).
          with(inventory_unit, "sold")

        order.should_receive(:inventory_adjusted=).with(false)

        order.make_dropship
      end

    end

    context "with no inventory adjustments" do
      before do
        order.inventory_adjusted = false
      end

      it "should not adjust variant stock and then update inventory units" do
        order.should_not_receive(:adjust_variant_stock)

        order.should_receive(:update_inventory_unit).
          with(inventory_unit, "sold")

        order.make_dropship
      end
    end

  end

  context "#make_regular" do
    before :each do
      order.is_dropship = false
      order.inventory_adjusted = true
      order.stub(:is_dropship_was => true)
    end

    context "with sufficient stock" do
      before do
        @variant1.stub(:on_hand => @line_items.first.quantity)
        @variant1.stub(:count_on_hand => @line_items.first.quantity)
      end

      it "should update inventory unit with state 'sold'" do
        order.should_receive(:update_inventory_unit).with(inventory_unit, "sold")
        order.make_regular
      end
    end

    context "with insufficient stock" do
      before do
        @variant1.stub(:on_hand => 0)
        @variant1.stub(:count_on_hand => 0)
      end

      it "should update inventory unit with state 'backordered'" do
        order.should_receive(:update_inventory_unit).with(inventory_unit, "backordered")
        order.make_regular
      end
    end

    context "with partial stock" do
      before do
        @variant1.stub(:on_hand => 1)
        @variant1.stub(:count_on_hand => 1)
        @line_items.first.stub(:quantity => 2)
        inventory2.stub(:save => true)
        order.stub(:inventory_units => [inventory_unit, inventory2])
        order.stub(:variant_inventory_units => [inventory_unit, inventory2])
      end

      it "with order quantity of 2 it should sell one unit and backorder the other" do
        order.should_receive(:update_inventory_unit).with(inventory_unit, "sold")
        order.should_receive(:update_inventory_unit).with(inventory2, "backordered")
        order.make_regular
      end

    end

    context "with no inventory adjustments" do

      before :each do
        order.inventory_adjusted = false 
      end

      it "should lower variant stock and set inventory adjusted flag " do
        order.should_receive(:adjust_variant_stock).
          with(@line_items.first.variant, @line_items.first.quantity * -1)

        order.should_receive(:inventory_adjusted=).with(true)

        order.make_regular
      end
    end    
  end

  context "#adjust_variant_stock" do

    context "with positive quantity" do
      it "should call variant.receive" do
        @variant1.should_receive(:receive).with(@line_items.first.quantity)
        order.adjust_variant_stock(@variant1, @line_items.first.quantity)
      end
    end

    context "with negative quantity" do
      it "should call variant.decrement!" do
        @variant1.should_receive(:decrement!).with(:count_on_hand, @line_items.first.quantity)
        order.adjust_variant_stock(@variant1, (@line_items.first.quantity * -1))
      end
    end
  end

  context "#update_inventory_unit" do
    before do
      order.stub(:is_dropship => true)
    end

    it "should set the state, dropship status and then save" do
      inventory_unit.should_receive(:state=).with("sold")
      inventory_unit.should_receive(:is_dropship=).with(true)
      inventory_unit.should_receive(:save).with(validate: false)
      order.update_inventory_unit(inventory_unit, "sold")
    end
  end

  context "#pending_credit_card_payment_total" do
    it "should sum all credit card amounts" do
      order.pending_credit_card_payment_total.should == payment1.amount
    end
  end

  context "#pending_credit_card_payment_total" do
    it "should sum all check payment amounts" do
      order.pending_check_payment_total.should == payment2.amount
    end

  end

  context "#pending_payments" do
    it "should return pending payments" do
      order.pending_payments.should == [payment1, payment2]
    end
  end

  context "#try_to_capture_payment" do
    before :each do
      order.stub(:staff_comments => "")
      order.stub(:update_staff_comments).and_return(true)
      order.stub(:total).and_return(payment1.amount + payment2.amount)

      payment1.stub(:capture!).and_return(true)
      payment1.stub(:save).and_return(true)

      payment2.stub(:capture!).and_return(true)
      payment2.stub(:save).and_return(true)
    
    end

    it "should total credit_card payments" do
      order.should_receive(:pending_credit_card_payment_total)
      order.try_to_capture_payment
    end

    it "should total check payments" do
      order.should_receive(:pending_check_payment_total)
      order.try_to_capture_payment
    end

    context "order total matches payments total" do
      it "should capture! payment" do
        payment1.should_receive(:capture!)
        payment1.should_receive(:save)
        
        payment2.should_receive(:capture!)
        payment2.should_receive(:save)
        
        order.try_to_capture_payment
      end
    end

    context "order total does not match payments total" do
      before :each do 
        order.stub(:total).and_return(payment1.amount)
      end

      it "should not capture payments and then update staff comments" do
        payment1.should_not_receive(:capture!)
        payment2.should_not_receive(:capture!)
        order.should_receive(:update_staff_comments).with("Payment totals did not match order total")
      end
    end
  end

  context "#try_to_ship_shipments" do

  end
  
  context "#update_staff_comments" do
    it "should update staff_comments without callbacks if column is available" do
      order.stub(:staff_comments => "")
      order.should_receive(:update_attributes_without_callbacks).with({ :staff_comments => "\ntesting\n"})
      order.update_staff_comments("testing")
    end

    it "should not update staff_comments if column is unavailable" do
      order.should_not_receive(:update_attributes_without_callbacks)
      order.update_staff_comments("testing")
    end
  end


end


