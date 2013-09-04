module Spree
  class PurchaseOrderMailer < BaseMailer

    def email_supplier(purchase_order, resend = false)
      @purchase_order = @po = purchase_order

      if resend
        type = "Resend"

      else 
        type = "New"
      end

      subject = "[#{Spree::Config[:site_name]}] #{type} #{@po.po_type} ##{@po.number}"
      sleep 1
      ext = @po.hardcopy_extension
      attachments["#{@po.number}.#{ext}"] = File.join(Rails.root,"tmp",@po.number + ".#{ext}")
      mail(:to => @po.supplier.email.split(";"), 
           :cc => @po.supplier_contact.email.split(";"), 
           :bcc => [@po.user.email, "zach@800ceoread.com"], 
           :reply_to => @po.user.email, 
           :subject => subject)

    end
  end
end

