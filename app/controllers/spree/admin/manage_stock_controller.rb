module Spree
  module Admin
    class ManageStockController < BaseController

      def index

      end

      def update
        @variant = Spree::Variant.find(params[:variant_id])

        if request.post?
        end
      end

    end
  end
end


