module Spree
  module Admin
    class SuppliersController < ResourceController
      before_filter :load_data, only: [:new, :create, :edit, :update]

      def load_data
        @supplier = (params[:id] ? Spree::Supplier.find(params[:id]) : Spree::Supplier.new)

        @supplier_contact = @supplier.supplier_contacts.new
      end
    end
  end
end
