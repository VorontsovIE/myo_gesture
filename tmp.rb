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

class Array
  def sum(val = 0.0); inject(val, &:+); end
  def mean; size == 0 ? nil : sum / size; end
  alias_method :average, :mean
  def median; self.sort[size/2]; end
  def variance; return nil if size == 0 ;  m = mean; self.map{|x| (x-m)**2 }.sum / size; end
  def stddev; return nil if size < 2; (variance * size / (size - 1))**0.5; end
  def quantile(alpha); sort[(alpha * size).round] end
  def window_sum(window_sz)
    raise if size < window_sz
    each_cons(window_sz).map{|elems| elems.sum}
  end
  def mean_geometric; map{|x| x**2 }.mean ** 0.5; end
  
  def median_filter(window_sz); each_cons(window_sz).map{|elems| elems.median } ; end
  def pvalue(el)
    sort.each_with_index.bsearch{|x,ind| x >= el }.last.to_f / size
  end

  def truncate(lower_threshold: nil, lower_subst: 0, upper_threshold: nil, upper_subst: 0)
    result = self
    result = result.map{|x| x < lower_threshold ? lower_subst : x} if lower_threshold
    result = result.map{|x| x < upper_threshold ? upper_subst : x} if upper_threshold
    result
  end

  def to_pvalues
    each_with_index.sort_by{|val, ind| val }.each_with_index.sort_by{|(val, ind), sorted_ind| ind }.map{|(val, ind), sorted_ind| sorted_ind.to_f / size }
  end
end

raise 'Specify filename with event log' unless event_log_filename = ARGV[0]

def store_emg_tsv(events, filename, sensors: 0...8)
  emg_events = events.select(&:emg?)
  selected_emg_events = emg_events.chunk(&:timestamp).map{|ts, evs| evs[0] } # only first track with same timestamps
  #emg_events.select{||}
  File.open(filename, 'w'){|fw|
    emg_timestamps = selected_emg_events.map(&:timestamp)
    fw.puts ['Timestamp', *emg_timestamps].join("\t")
    sensors.each{|emg_index|
      emg_strengths = selected_emg_events.map{|ev| ev.data[:emg][emg_index]}
      fw.puts ["Sensor #{emg_index}", *emg_strengths].join("\t")
    }
  }
end



lns = File.readlines(event_log_filename)
log = lns.map(&:chomp).reject(&:empty?).map{|l| JSON.parse(l) }
events = log.select{|info| info[0] == 'event' }.map{|info| MyoEvent.from_hash(info[1]) }
events = events.chunk(&:timestamp).map{|ts, evs| evs.first } # only first track with same timestamps

start_time = events.first.timestamp
events.each{|ev| ev.normalize_timestamp!(start_time) }

unlocked_timestamps = events.select{|ev| ev.type == :unlocked }.map(&:timestamp)
locked_timestamps = events.select{|ev| ev.type == :locked }.map(&:timestamp)
lock_unlock_timestamps = unlocked_timestamps + locked_timestamps 

emg_events = events.select(&:emg?)
emg_timestamps = emg_events.map(&:timestamp)

# deltats = emg_timestamps.each_cons(2).map{|x,y| y-x}
# $stderr.puts [deltats.mean, deltats.median, deltats.stddev].inspect
# $stderr.puts deltats.sort

# emg_events.map{|ev| ev.data[:emg].map(&:abs) } 
# .transpose.map{|series| series.median_filter(7) }.transpose
# .transpose.map{|series| series.truncate(lower_threshold: series.quantile(0.95)) }.transpose # .transpose.map{|series| series.each_cons(20).map{|elems| elems.mean_geometric} }.transpose #.transpose.map{|series| series.to_pvalues }.transpose
emg_events.map{|ev| ev.data[:emg].map(&:abs) } 
.transpose.map{|series| series.median_filter(7) }.transpose
.transpose.map{|series| series.truncate(lower_threshold: series.quantile(0.95)) }.transpose
.transpose.map{|series| series.each_cons(20).map{|elems| elems.mean_geometric} }.transpose #.transpose.map{|series| series.to_pvalues }.transpose  #.transpose.map{|series| series.window_sum(200) }.transpose
.each_with_index{|row, ind|
  if unlocked_timestamps.any?{|tm| ( emg_timestamps[ [ind - 1, 0].max ] ... emg_timestamps[ ind ] ).include?(tm) }
    50.times{
      puts ([-30] * 8).join("\t")
    }
  end
  if locked_timestamps.any?{|tm| ( emg_timestamps[ [ind - 1, 0].max ] ... emg_timestamps[ ind ] ).include?(tm) }
    50.times{
      puts ([-10] * 8).join("\t")
    }
  end
  puts [emg_timestamps[ind], *row].join("\t")
}
# map{|ev|
#   ev.data[:emg][ind].abs 
# }.window_sum(50).join("\n")


event_series = events.slice_before{|ev| ev.type == :unlocked }
                .map{|ev_iter| ev_iter.take_while{|ev| ev.type != :locked } }
                .drop(1)
                .reject{|ev_log| ev_log.size < 50 }


# FileUtils.mkdir_p('samples/a')
# event_series.each_with_index{|letter_event_log, ind|
#   store_emg_tsv(letter_event_log, "samples/a/#{ind}.tsv")
# }

# event_series.each{|ev_log|
#   emgs = ev_log.select(&:emg?).map{|ev| ev.data[:emg] }
#   emg_stddevs = 8.times.map{|emg_index|
#     emg_index = - emg_index
#     emgs.map{|emg| emg[emg_index] }.stddev
#   }
#   normed_emg_stddevs = emg_stddevs.map{|x| x / emg_stddevs[0] }
#   puts normed_emg_stddevs.map{|x| x.round(3) }.join("\t")

#   # emg_quantiles = 8.times.map{|emg_index|
#   #   emgs.map{|emg| emg[emg_index] }.quantile(0.95)
#   # }
#   # # puts emg_quantiles.map{|x| x.round }.join("\t")
# }


# event_series.map{|ev_log|
#   emgs = ev_log.select(&:emg?).map{|ev| ev.data[:emg] }
#   emg_quantiles = [2].each.map{|emg_index|
#     # gini index
#     emg_sensor_data = emgs.map{|emg| emg[emg_index] }
#     abs_emg_sensor_data = emg_sensor_data.map(&:abs)
#     p (0.1..0.9).step(0.1).map{|q| abs_emg_sensor_data.quantile(q) }
#     abs_emg_sensor_data.quantile(0.2).to_f / abs_emg_sensor_data.quantile(0.8).to_f
#   }
# }.transpose.each_with_index.map{|sensor_quantiles, sensor_index|
#   puts ["Sensor #{sensor_index}", *[sensor_quantiles.mean, sensor_quantiles.stddev, sensor_quantiles.stddev / sensor_quantiles.mean].map{|x| x.round(3)}].join("\t")
# }


# (0...8).each{|emg_index|
#   event_series.map{|ev_log|
#     emgs = ev_log.select(&:emg?).map{|ev| ev.data[:emg] }
#     emg_sensor_data = emgs.map{|emg| emg[emg_index] }
#     puts emg_sensor_data.window_sum(10).join("\t")
#     # abs_emg_sensor_data = emg_sensor_data.map(&:abs)
#     # emg_quantiles = abs_emg_sensor_data.quantile(0.9)
#     # puts (0.1..0.9).step(0.1).map{|q| abs_emg_sensor_data.quantile(q) }.join("\t")
#     # puts abs_emg_sensor_data.sort.join("\t")
#   }
# }


#######################################
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
