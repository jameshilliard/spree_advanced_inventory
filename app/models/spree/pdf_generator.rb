module Spree
  class PdfGenerator < Prawn::Document
 
    def initialize(options)
      options && options.merge!({:inline=>true})
      create_instance_variables(options.delete(:variables))
      super(options)
    end

    def render_template(template)
      pdf = self
      pdf.instance_eval do
        eval(template) #this evaluates the template with your variables
      end
      ensure_path
      pdf.render_file(File.join(output_path,filename))
    end

    private

    def create_instance_variables(vars)
      return if vars.blank?
      vars.each_pair do |k,v|
          instance_variable_set("@#{k}", v)
      end
    end

    def output_path
      @output_path ||= File.join(Rails.root,'tmp','documents')
    end

    def ensure_path
      FileUtils.mkdir_p(output_path)
    end

    def filename
      @output_file ||= "#{Process.pid}::#{Thread.current.object_id}.pdf"
    end
  end
end

