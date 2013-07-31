module Spree
  module Admin
    class SuppliersController < ResourceController
      before_filter :copy_rtf, only: [:create, :update]

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
