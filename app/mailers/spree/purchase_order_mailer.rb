module Spree
  class PurchaseOrderMailer < BaseMailer

    def email_supplier(purchase_order, resend = false)
      @purchase_order = @po = purchase_order

      subject = "[#{Spree::Config[:site_name]}] New #{@po.po_type} ##{@po.number}"
      sleep 1
      ext = @po.hardcopy_extension
      attachments["#{@po.number}.#{ext}"] = File.join(Rails.root,"tmp",@po.number + ".#{ext}")
      mail(:to => @po.supplier.email, :cc => @po.supplier_contact.email, :bcc => @po.user.email, :reply_to => @po.user.email, :subject => subject)

    end
  end
end

