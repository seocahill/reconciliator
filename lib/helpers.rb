module Helpers

  def date_as_integer(row, owner)
    if owner == "bank"
      Date.strptime(row[1], "%m/%d/%y").to_time.to_i
    else
      Date.parse(row[4]).to_time.to_i
    end
  end

  def balances(bank_item, client_item)
    bank_tot = str_to_num(bank_item[6])
    client_tot = str_to_num(client_item[11])
    bank_tot + client_tot == 0
  end

  def match_items(original, match)
    @records[original][:match_id], @records[match][:match_id] = match, original
  end

  def row_amount(data, owner)
    idx = owner == "bank" ? 6 : 11
    str_to_num(data[idx])
  end

  def row_details(data, owner)
    idx = owner == "bank" ? 4 : 9
    data[idx]
  end

  def str_to_num(str)
    str.scan(/[-.0-9]/).join().to_f.round(2)
  end

  def records_to_csv_row(ids)
    rows = ids.map do |id| 
      data = @records[id][:data]
      data[0] = @records[id][:match_id].nil? ? "un-matched" : "matched"
      data
    end
    rows.empty? ? [["No results"]] : rows
  end

  def transaction_type(row, owner)
    if owner == "bank"
      row[2].strip
    else
      row[6].strip
    end
  end
end