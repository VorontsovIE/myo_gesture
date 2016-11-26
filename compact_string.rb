def most_common_element(arr)
  arr.each_with_object(Hash.new(0)){|elem, hsh|
    hsh[elem] += 1
  }.max_by{|elem, count|
    elem
  }.first
end

compactified_string = readline.each_char.each_cons(5).map{|letters|
  most_common_element(letters)
}.each_with_object(''){|letter, s|
  s << letter unless s[-1] == letter
}

puts compactified_string