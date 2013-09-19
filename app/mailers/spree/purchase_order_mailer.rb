module Spree
  class PurchaseOrderMailer < BaseMailer

    def completed_notice(po)
      @po = po
      @completed_at = po.updated_at.strftime("%m/%d/%Y %l:%M %P")

      mail(to: [(@po.user.email ? @po.user.email : from_address), "mel@800ceoread.com"], 
           from: from_address, 
           subject: "[#{po.number}] Purchase order received at #{@completed_at}") 
    end

    def email_supplier(purchase_order, resend = false)
      @purchase_order = @po = purchase_order

      if resend
        type = "Resend"

      else 
        type = "New"
      end

      subject = @po.email_subject || "[#{Spree::Config[:site_name]}] #{type} #{@po.po_type} ##{@po.number}"
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

