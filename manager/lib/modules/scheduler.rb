
require 'modules/scheduler/job'
require 'modules/scheduler/drivers'
require 'modules/scheduler/resque' if Scheduler.drivers.empty?

module Scheduler

  class << self

    def configure(config)
      driver.configure(config)
    end

    def schedule_in(time_in_sec, job)
      schedule_at_with_queue((Time.new + time_in_sec), job)
    end

    def schedule_in_with_queue(time_in_sec, job, queue="schedules")
      schedule_at_with_queue((Time.new + time_in_sec), job, queue)
    end

    def schedule_at(timestamp, job)
      schedule_at_with_queue(timestamp, job)
    end

    # this must be implemented by the scheduler implementation/driver
    # see resque driver for example
    def schedule_at_with_queue(timestamp, job, queue="schedules")
      driver.schedule_at_with_queue(timestamp, job, queue)
    end

  end

end


