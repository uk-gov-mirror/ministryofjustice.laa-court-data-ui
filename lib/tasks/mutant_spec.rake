# frozen_string_literal: true

# https://github.com/mbj/mutant/blob/master/docs/nomenclature.md
# subject can be:
# 1. Class - all methods and class methods in class
# 2. Module::Class - namespaced version of above
# 3. Module::Class.class_method - a specific class method
# 3. Module::Class#instance_method - a specific instance method
#
# e.g
# $ rake mutant_spec:for["CrackedIneffectiveTrialDecorator"]
#
namespace :mutant_spec do
  desc 'Mutation test the specified subject using rspec'
  task :for, [:subject] do |_task, args|
    cmd = "RAILS_ENV=test bundle exec mutant run -r ./config/environment --use rspec \"#{args[:subject]}\""
    system(cmd)
  end
end
