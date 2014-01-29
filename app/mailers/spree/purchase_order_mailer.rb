module Spree
  class PurchaseOrderMailer < BaseMailer
    def completed_notice(po)
      @po = po

      unless @po.dropship
        @completed_at = po.updated_at.strftime("%m/%d/%Y %l:%M %P")

        attention = ""

        @po.purchase_order_line_items.each do |l|
          if l.price.to_f == 0.0
            attention = "*** ATTENTION REQUIRED *** "
          end
        end

        mail(to: [(@po.user.email ? @po.user.email : from_address)], 
             from: from_address, 
             subject: "[#{po.number}] #{attention}Purchase order received at #{@completed_at}") 
      end
    end


    def email_supplier(purchase_order, resend = false)
      @purchase_order = @po = purchase_order

      if resend
        type = "Resend"

      else 
        type = "New"
      end

      subject = @po.email_subject
      if subject.blank? 
        subject = "[#{Spree::Config[:site_name]}] #{type} #{@po.po_type} ##{@po.number}"
      end

      sleep 1
      ext = @po.hardcopy_extension
      attachments["#{@po.number}.#{ext}"] = File.read(File.join(Rails.root,"tmp",@po.number + ".#{ext}"))
      mail(:to => @po.supplier.email.split(";"), 
           :from => from_address,
           :cc => @po.supplier_contact.email.split(";"), 
           :bcc => [@po.user.email], 
           :reply_to => @po.user.email, 
           :subject => subject)

    end
  end
end

