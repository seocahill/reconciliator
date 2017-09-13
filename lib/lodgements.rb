module Lodgements

  def process_lodgements
    @client_receipts = @records.select { |k,v| v[:owner] == "client" && v[:data][6].strip == "B/Rec" }
    @client_receipts.each do |key, record|
      matching_id = find_matching_bank_lodgement(record)
      match_items(key, matching_id) if matching_id
    end
  end

  def find_matching_bank_lodgement(record)
    date = date_as_integer(record[:data], record[:owner])
    match = @date_lookup[date].find do |id|
      guess = @records[id]
      guess[:type] == "DEP" &&
        guess[:match_id].nil? &&
          balance(guess[:data], record[:data])
    end
  end

  def print_lodgements
    matching_client_lodgements = @client_receipts.reject { |k,v| v[:match_id].nil? }
    matching_bank_lodgements = @records.values_at(*matching_client_lodgements.map { |k,v| v[:match_id] })

    CSV.open(@data_folder + "reconciled-lodgements.csv", "wb") do |csv|
      csv << ["Reconciled Lodgements from bank statements"]
      csv << @bank_items_header
      matching_bank_lodgements.map {|i| i[:data][1..-1] }.each { |row| csv << row }
      csv << [""]
      csv << ["Reconciled Lodgements from client's bank accounts"]
      csv << @client_items_header
      matching_client_lodgements.map {|k,v| v[:data][1..-1] }.each { |row| csv << row }
      csv << [""]
    end 
  end
end