namespace :finfore do

  desc "trace pid id from worker"
  task :trace_workers_pids  => :environment do
    system "ps -e -o pid,command | grep [r]esque-1"
  end
  
  desc "kill workers pids panicly"  
  task :kill_workers_pids  => :environment do
    child_pids = Array.new
    pipe = IO.popen("ps -e -o pid,command | grep [r]esque-1")
    pipe.readlines.each { |line|
      parts = line.split(/\s+/)
      pid =  parts[0].to_i < 1 ?  parts[1] :  parts[0]
      system "kill -9 "+pid
    }
  end
  
end
