module Spree
  module Admin
    class SuppliersController < ResourceController
      before_filter :copy_rtf, only: [:create, :update]
      before_filter :setup_new_supplier_contact, only: [:new, :edit]
      before_filter :setup_entered_supplier_contact, only: [:create, :update]

      def index
        params[:q] ||= {}

        @search = Spree::Supplier.accessible_by(current_ability, :index).ransack(params[:q])
        @suppliers = @search.result.includes([:supplier_contacts]).
          page(params[:page]).
          per(params[:per_page] || Spree::Config[:orders_per_page]).
          order("name asc")

        respond_with(@suppliers)        
      end

      def copy_rtf
        if params["rtf_template"]
          params[:supplier] = { rtf_template: "" }

          params["rtf_template"].tempfile.each_line do |l|
            params[:supplier][:rtf_template] += l
          end
        end
      end 

      def setup_new_supplier_contact
        @new_supplier_contact = Spree::SupplierContact.new

        if @supplier
          @new_supplier_contact.supplier = @supplier
        end
      end

      def setup_entered_supplier_contact
        if params[:supplier] and 
          params[:supplier][:supplier_contacts_attributes] and 
          params[:supplier][:supplier_contacts_attributes]["0"]

          logger.info "\n\n*** #{params[:supplier][:supplier_contacts_attributes]["0"].inspect}"
          @new_supplier_contact = Spree::SupplierContact.new(params[:supplier][:supplier_contacts_attributes]["0"])
        else
          logger.info "\n\n--- New supplier contact"
          setup_new_supplier_contact
        end
      end

    end
  end
end
