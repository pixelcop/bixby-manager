
module Bixby
  module ApiView

    class Host < ::ApiView::Base

      for_model ::Host

      def self.convert(obj)

        hash = attrs(obj, :id, :ip, :hostname, :alias, :desc)
        hash[:org] = obj.org.name

        return hash
      end

    end # Host

  end # ApiView
end # Bixby
