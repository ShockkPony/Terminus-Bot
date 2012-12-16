#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2012 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# (http://terminus-bot.net/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

module Bot
  EventData = Struct.new :name, :owner, :func, :blk

  class EventManager < Hash

    # Create a new event. The key in the hash table is the event name
    # which is used to run the event. The value is an array which will store
    # the multiple events that run are run when the event name is called.
    def create name, owner, func = nil, &blk
      self[name] ||= []

      $log.debug("events.create") { "Created event #{name}" }
      self[name] << EventData.new(name, owner, func, blk)
    end

    # Run all the events with the given name.
    def dispatch name, msg = nil
      return unless self.has_key? name

      $log.debug("events.dispatch") { name }

      self[name].each do |event|
        begin
          Event.dispatch event.owner, event.name, event.func, msg, &event.blk
        rescue => e
          $log.error("events.run") { "Error running event #{name}: #{e}" }
          $log.debug("events.run") { "Backtrace for #{name}: #{e.backtrace}" }
        end
      end
    end

    def dispatch_for owner, name, msg = nil
      return unless self.has_key? name

      $log.debug("events.dipatch_for") { "#{owner} #{name}" }

      self[name].each do |event|
        begin
          next unless event.owner == owner

          Event.dispatch event.owner, event.name, event.func, msg, &event.blk
        rescue => e
          $log.error("events.run") { "Error running event #{name}: #{e}" }
          $log.debug("events.run") { "Backtrace for #{name}: #{e.backtrace}" }
        end
      end
    end

    # Delete all the events owned by the given class.
    def delete_for owner
      self.each do |n, a|
        a.delete_if {|e| e.owner == owner}
      end
    end

  end

  class Event < Command
    class << self
      def dispatch owner, name, func, msg = nil, &blk
        helpers &owner.get_helpers if owner.respond_to? :helpers

        if block_given?
          if msg.nil?
            self.new(owner, name).instance_eval &blk
          else
            self.new(owner, name, msg).instance_eval &blk
          end
        else
          if msg.nil?
            owner.send func
          else
            owner.send func, msg
          end
        end
      end
    end

    def initialize owner, name, msg = nil
      super owner, msg, nil
    end
  end

  Events ||= EventManager.new
end