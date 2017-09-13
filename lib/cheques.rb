module Cheques

  def process_cheques
    @records.each do |key, item|
      if is_cheque(item)
        item[:type] = "cheque"
        store_in_cheque_ledger(item[:data], item[:owner])
      end
    end
    reconcile_cheques
  end

  def reconcile_cheques
    @cheque_ledger.each do |key, bucket|
      bucket[:bank].each do |i|
        next unless @records[i][:match_id].nil?
        matching_client_cheque_id = bucket[:client]
          .reject { |k| k == i }
          .find { |j| balances(@records[i][:data], @records[j][:data]) }
        if matching_client_cheque_id
          match_items(i, matching_client_cheque_id)
        end
      end
    end
  end

  def print_cheques
    matching_records = @records.select { |k,v| v[:match_id] != nil && is_cheque(v) }
    matched_bank_cheques = matching_records.values
      .select { |v| v[:owner] == 'bank' }
      .each { |v| add_tot(v[:data], v[:owner], "matching-cheques") }
      .map { |r| r[:data][1..-1] }
    matched_client_cheques = matching_records.values
      .select { |v| v[:owner] == 'client' }
      .each { |v| add_tot(v[:data], v[:owner], "matching-cheques") }
      .map { |r| r[:data][1..-1] }

    sheet = @excel_obj.workbook.add_worksheet(:name => "Reconciled cheques")
    sheet.add_row ["Reconciled Cheques from bank statements"]
    sheet.add_row @bank_items_header
    matched_bank_cheques.each { |row| sheet.add_row row }
    sheet.add_row [""]
    sheet.add_row ["Reconciled Cheques from client's bank accounts"]
    sheet.add_row @client_items_header
    matched_client_cheques.each { |row| sheet.add_row row }
  end

  def print_unreconciled_cheques
    sheet = @excel_obj.workbook.add_worksheet(:name => "Unreconciled cheques")
    sheet.add_row ["Unreconciled Cheques sorted by amount and cheque number"]
    sheet.add_row ["Type", "Date", "Ref", "Details", "Amount", "Match", "Row data per statement / account -->"]
    unreconciled_cheques_list
      .values
      .sort_by{ |i| [row_amount(i[:data], i[:owner]).abs, i[:date]] }
      .each { |v| 
        add_tot(v[:data], v[:owner], "unreconciled-cheques") 
        match_odd_cheques(v)
      }
      .map {|i| [
        i[:owner],
        Time.at(i[:date]).strftime('%d/%m/%y'),
        cheque_number(i[:data], i[:owner]),
        row_details(i[:data], i[:owner]),
        row_amount(i[:data], i[:owner]),
        i[:guess],
        ] + i[:data][1..-1] 
      }
      .each { |row| sheet.add_row row }
    sheet.add_row [""]
  end

  def unreconciled_cheques_list
    @records.select { |k,v| is_cheque(v) && v[:match_id].nil? }
  end

  private

  def is_cheque(row)
    if row[:data][4] && row[:owner] == "bank"
      row[:data][4].include?("Cheque No") || row[:data][4].include?("CQ No") || row[:data][4].include?("Chq No") 
    elsif row[:data][4]
      row[:data][6].strip == "B/Pay"
    end
  end

  def cheque_number(item, owner)
    if owner == "client"
      item[8].to_i
    else
      item[5].to_i
    end
  end

  def store_in_cheque_ledger(item, owner)
    key = cheque_number(item, owner)
    bucket = @cheque_ledger[key] ||= { client: [], bank: [] }
    bucket[owner.to_sym] << item[0]
  end

  def match_odd_cheques(row)
    return if row[:owner] == 'bank' || row[:guess] == 'x'
    match = unreconciled_cheques_list.find do |k,v|
      v[:guess] != 'x' &&
      v[:owner] == 'bank' &&
      # the bank date must be later than the entry in the clients accounts
      Time.at(v[:date]) >= Time.at(row[:date]) && 
      row_amount(v[:data], v[:owner]).round + row_amount(row[:data], row[:owner]).round == 0
    end
    if match 
      row[:guess] = "x"
      match[1][:guess] = "x"
    end
  end
end