
if Object.const_defined? :Capistrano then

  namespace :thin do
    %w(start stop restart).each do |action|
      desc "#{action.capitalize} the Thin cluster"
      task action.to_sym do
        run "#{sudo} god restart thin-bixby"
      end
    end
  end

end
