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

sensor_tracks = emg_events.map{|ev| ev.data[:emg].map(&:abs) }.transpose

# sensor_tracks
#   .map{|series| series.median_filter(7) }
#   .map{|series| series.truncate(lower_threshold: series.quantile(0.95)) } 
#   .map{|series| series.each_cons(20).map{|elems| elems.mean_geometric} }
sensor_tracks
  .map{|series|
    series.each_slice(30).each_cons(3).map(&:flatten).map(&:sum) # 900ms with 300ms shifts
  }
  .transpose
  .each_with_index{|tracks_snapshot, ind|
    puts tracks_snapshot.join("\t")
  }
