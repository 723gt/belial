require 'rake/testtask'

# rake test（または rake）で test/ 以下のすべてのテストを実行する
Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/*/*_test.rb']
  t.warning = false
end

task default: :test
