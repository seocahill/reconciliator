module Tots

  def add_tot(row, owner, type)
    amount = row_amount(row, owner)
    @tots[owner.to_sym][type] ||= 0
    @tots[owner.to_sym][type] += amount
  end

  def print_tots
    sheet = @excel_obj.workbook.add_worksheet(:name => "Tots")
    sheet.add_row ["","Bank","Client"]
    sheet.add_row ["cheques and debits", @tots[:bank]["WDL"], client_cheques_and_debits]
    sheet.add_row ["lodgements", bank_lodgements, @tots[:client]["B/Rec"]]
    sheet.add_row [""]
    sheet.add_row ["reconciled cheques", @tots[:bank]["matching-cheques"],  @tots[:client]["matching-cheques"]]
    sheet.add_row ["reconciled debits", @tots[:bank]["matching-debits"],  @tots[:client]["matching-debits"]]
    sheet.add_row ["unreconciled cheques", @tots[:bank]["unreconciled-cheques"],  @tots[:client]["unreconciled-cheques"]]
    sheet.add_row ["unreconciled debits", @tots[:bank]["unreconciled-debits"],  @tots[:client]["unreconciled-debits"]]
  end

  def client_cheques_and_debits
    @tots[:client]["B/Pay"] || 0 + @tots[:client]["B/Ctf"] || 0
  end

  def bank_lodgements
    @tots[:bank]["DEP"] || 0 + @tots[:bank]["TLOG"] || 0
  end
end