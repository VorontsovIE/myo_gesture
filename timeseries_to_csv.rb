require 'json'
require 'fileutils'

MyoEvent = Struct.new(:type, :timestamp, :myo, :data) do
  def self.from_hash(hsh)
    data = hsh.reject{|k,v| ['type', 'timestamp', 'myo'].include?(k) }.map{|k,v| [k.to_sym, v] }.to_h
    self.new(hsh['type'].to_sym, hsh['timestamp'].to_i, hsh['myo'], data)
  end

  def pose?; type == :pose; end
  def orientation?; type == :orientation; end
  def emg?; type == :emg; end
  def normalize_timestamp!(start_time); self.timestamp -= start_time; end
end

raise 'Specify filename with event log' unless event_log_filename = ARGV[0]

def store_emg_tsv(events, filename)
  emg_events = events.select(&:emg?)
  selected_emg_events = emg_events.chunk(&:timestamp).map{|ts, evs| evs[0] } # only first track with same timestamps
  #emg_events.select{||}
  File.open(filename, 'w'){|fw|
    emg_timestamps = selected_emg_events.map(&:timestamp)
    fw.puts ['Timestamp', *emg_timestamps].join("\t")
    8.times{|emg_index|
      emg_strengths = selected_emg_events.map{|ev| ev.data[:emg][emg_index]}
      fw.puts ["Sensor #{emg_index}", *emg_strengths].join("\t")
    }
  }
end

lns = File.readlines(event_log_filename)
log = lns.map(&:chomp).reject(&:empty?).map{|l| JSON.parse(l) }
events = log.select{|info| info[0] == 'event' }.map{|info| MyoEvent.from_hash(info[1]) }
start_time = events.first.timestamp
events.each{|ev| ev.normalize_timestamp!(start_time) }
event_series = events.slice_before{|ev| ev.type == :unlocked }.map{|ev_iter| ev_iter.take_while{|ev| ev.type != :locked } }.drop(1)

FileUtils.mkdir_p('samples/letter_A')
event_series.each_with_index{|letter_event_log, ind|
  store_emg_tsv(letter_event_log, "samples/letter_A/#{ind}.tsv")
}

# emg_events = events.select(&:emg?)
# grouped_emg_events = emg_events.chunk(&:timestamp).select{|ts, evs| evs.size == 2 }

# timestamps =  grouped_emg_events.map{|ts, (ev1, ev2)| ts }
# puts timestamps.join("\t")
# 8.times{|emg_index|
#   emg_row = grouped_emg_events.map{|ts, (ev1, ev2)|
#     ev1.data[:emg][emg_index]
#   }
#   puts emg_row.join("\t")
# }
# 8.times{|emg_index|
#   emg_row = grouped_emg_events.map{|ts, (ev1, ev2)|
#     ev2.data[:emg][emg_index]
#   }
#   puts emg_row.join("\t")
# }
# #events.chunk(&:pose?).map{||}
