rm samples/*/*.tsv

# # ruby timeseries_to_csv.rb  samples/a/raw-s.log as  >  samples/a/raw-s.tsv
# # ruby timeseries_to_csv.rb  samples/a/raw-d.log ad  >  samples/a/raw-d.tsv

# # ruby timeseries_to_csv.rb  samples/b/raw-s.log bs  >  samples/b/raw-s.tsv
# # ruby timeseries_to_csv.rb  samples/b/raw-d.log bd  >  samples/b/raw-d.tsv

# # ruby timeseries_to_csv.rb  samples/nothing-table/raw-s.log nts  >  samples/nothing-table/raw-s.tsv
# # ruby timeseries_to_csv.rb  samples/nothing-table/raw-d.log ntd  >  samples/nothing-table/raw-d.tsv

# # ruby timeseries_to_csv.rb  samples/nothing-vertical/raw-s.log nvs  >  samples/nothing-vertical/raw-s.tsv
# # ruby timeseries_to_csv.rb  samples/nothing-vertical/raw-d.log nvd  >  samples/nothing-vertical/raw-d.tsv


# ruby timeseries_to_csv.rb  samples/a/raw-s.log a  >  samples/a/raw-s.tsv
# # ruby timeseries_to_csv.rb  samples/a/raw-d.log a  >  samples/a/raw-d.tsv

# ruby timeseries_to_csv.rb  samples/b/raw-s.log b  >  samples/b/raw-s.tsv
# # ruby timeseries_to_csv.rb  samples/b/raw-d.log b  >  samples/b/raw-d.tsv

# ruby timeseries_to_csv.rb  samples/nothing-table/raw-s.log n  >  samples/nothing-table/raw-s.tsv
# # ruby timeseries_to_csv.rb  samples/nothing-table/raw-d.log n  >  samples/nothing-table/raw-d.tsv

# ruby timeseries_to_csv.rb  samples/nothing-vertical/raw-s.log n  >  samples/nothing-vertical/raw-s.tsv
# ruby timeseries_to_csv.rb  samples/nothing-vertical/raw-d.log n  >  samples/nothing-vertical/raw-d.tsv


# ruby timeseries_to_csv.rb  samples/a/raw-30s.log a  >  samples/a/raw-30s.tsv
# ruby timeseries_to_csv.rb  samples/b/raw-30s.log b  >  samples/b/raw-30s.tsv
ruby timeseries_to_csv.rb  samples/a/raw-60s.log a  >  samples/a/raw-60s.tsv
ruby timeseries_to_csv.rb  samples/b/raw-60s.log b  >  samples/b/raw-60s.tsv

for letter in r c; do
  for i in {1..6}; do
    ruby timeseries_to_csv.rb  samples/${letter}/raw-5s-${i}.log ${letter}  >  samples/${letter}/raw-5s-${i}.tsv
  done
  cat samples/${letter}/raw-5s-*.tsv > samples/${letter}/raw-5s.tsv
  rm samples/${letter}/raw-5s-*.tsv
done

# ruby timeseries_to_csv.rb  samples/a/raw-5s.log a  >  samples/a/raw-5s.tsv
# ruby timeseries_to_csv.rb  samples/b/raw-5s.log b  >  samples/b/raw-5s.tsv
# ruby timeseries_to_csv.rb  samples/nothing-vertical/raw-5s.log  nv  > samples/nothing-vertical/raw-5s.tsv


# ruby timeseries_to_csv.rb  samples/right/raw.log  r  > samples/right/raw.tsv
# ruby timeseries_to_csv.rb  samples/nothing-table/raw-30s.log  n  > samples/nothing-table/raw-30s.tsv
# ruby timeseries_to_csv.rb  samples/nothing-table/raw-60s.log  nt  > samples/nothing-table/raw-60s.tsv
ruby timeseries_to_csv.rb  samples/nothing-vertical/raw-60s.log  nv  > samples/nothing-vertical/raw-60s.tsv

# cat samples/*/raw-{s,d}.tsv > train.tsv
cat samples/*/*.tsv > train.tsv


