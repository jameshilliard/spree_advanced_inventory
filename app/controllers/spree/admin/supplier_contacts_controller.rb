module Spree
  module Admin
    class SupplierContactsController < ResourceController
      before_filter :load_data, only: [:new, :create, :edit, :update, :destroy]

      def index
        redirect_to edit_admin_supplier_path(request.env["HTTP_REFERER"].split(/\//).last)
      end

      def load_data
        @supplier_contact = (params[:id] ?
                             Spree::SupplierContact.find(params[:id]) :
                             Spree::SupplierContact.new)

        @supplier = @supplier_contact.supplier
      end
    end
  end
end

