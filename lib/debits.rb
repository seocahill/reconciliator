module Debits

  def process_debits
    @client_debits = @records.select { |k,v| v[:owner] == "client" && is_debit(v) }
    @client_debits.each do |key, record|
      matching_id = find_matching_bank_debit(record)
      match_items(key, matching_id) if matching_id
    end
  end

  def find_matching_bank_debit(record)
    date = date_as_integer(record[:data], record[:owner])
    match = @date_lookup[date].find do |id|
      guess = @records[id]
      is_debit(guess) && 
        guess[:match_id].nil? &&
          balances(guess[:data], record[:data])
    end
  end

  def print_debits
    sheet = @excel_obj.workbook.add_worksheet(:name => "Reconciled debits")
    sheet.add_row ["Reconciled Debits from bank statements"]
    sheet.add_row @bank_items_header
    matching_bank_debits
      .each { |v| add_tot(v[:data], v[:owner], "matching-debits") }
      .map {|i| i[:data][1..-1] }
      .each { |row| sheet.add_row row }
    sheet.add_row [""]
    sheet.add_row ["Reconciled Debits from client's bank accounts"]
    sheet.add_row @client_items_header
    matching_client_debits
      .each { |k,v| add_tot(v[:data], v[:owner], "matching-debits") }
      .map {|k,v| v[:data][1..-1] }
      .each { |row| sheet.add_row row }
    sheet.add_row [""]
  end

  def matching_client_debits
    @client_debits.reject { |k,v| v[:match_id].nil? }
  end

  def matching_bank_debits
    @records.values_at(*matching_client_debits.map { |k,v| v[:match_id] })
  end

  def print_unreconciled_debits
    sheet = @excel_obj.workbook.add_worksheet(:name => "Unreconciled debits")
    sheet.add_row ["Unreconciled Debits sorted by amount and date"]
    sheet.add_row ["Type", "Date", "Ref", "Details", "Amount", "Match", "Row data per statement / account -->"]
    unreconciled_debits_list
      .values
      .sort_by{ |i| [row_amount(i[:data], i[:owner]), date_as_integer(i[:data], i[:owner])] } 
      .each { |v| add_tot(v[:data], v[:owner], "unreconciled-debits") }
      .map {|i| [
        i[:owner],
        Time.at(i[:date]).strftime('%d/%m/%y'),
        cheque_number(i[:data], i[:owner]),
        row_details(i[:data], i[:owner]),
        row_amount(i[:data], i[:owner]),
        " ",
        ] + i[:data][1..-1] 
      }
      .each { |row| sheet.add_row row }
    sheet.add_row [""]
  end

  def unreconciled_debits_list
    @records.select { |k,v| v[:match_id].nil? && is_debit(v) }
  end

  def is_debit(row)
    ["WDL", "B/Ctf"].include?(row[:type]) && !is_cheque(row)
  end

  def select_best_match(bank_item, client_items)
    if client_items.length == 1
      client_items.first
    else
      match = match_by_nearest_date(bank_item[:date], client_items)
    end
  end

  def match_by_nearest_date(bank_item_date, client_items)
    client_items.min_by do |cc|
      client_date = records[cc][:date] 
      (bank_item_date - client_date).abs 
    end
  end

  def match_transfers_on_same_date
    @bank_unreconciled.each do |row|
      if !is_cheque(row)
        if match = find_date_matches(row)
          @matching_transfers << [row, match]
          @bank_unreconciled.delete(row)
          @client_parsed.delete(match)
        end
      end
    end
  end

  def match_transfer(row)
    bank_key = bank_transfer_key(row)
    @client_parsed[1..-1].find do |ci|
      bank_key == client_transfer_key(ci)
    end
  end

  def client_transfer_key(row)
    date = Date.parse(row[3]).to_time.to_i
    amount = str_to_num(row[11])
    key = date + amount
  end

  def find_date_matches(row)
    bank_date = Date.strptime(row[0], "%m/%d/%Y").to_time.to_i
    @client_parsed[1..-1].find {|i| Date.parse(i[3]).to_time.to_i == bank_date }
  end

  def bank_transfer_key(row)
    date = Date.strptime(row[0], "%m/%d/%Y").to_time.to_i
    amount = str_to_num(row[5])
    key = date + amount
  end
end