module Spree
  module Admin
    class SuppliersController < ResourceController
      before_filter :copy_rtf, only: [:create, :update]

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

    end
  end
end
