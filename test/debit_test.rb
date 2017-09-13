require 'minitest/autorun'
require 'pry-rescue/minitest'
require_relative '../app'

class DebitTest < Minitest::Test

  def setup
    @app = Reconciler.new
    @app.instance_variable_set(:@data_folder, __dir__ + "/../fixtures/debits/")
    @app.store_records
  end

  def test_storage
    assert_equal @app.records.length, 13, "parse and store csv records in a hash"
  end

  def test_process_debits
    @app.process_debits
    assert_equal @app.client_debits.length, 5, "got all the client debits"
  end

  def test_reconciled_list
    @app.process_debits
    expected_client = [["B2", "B. BANK    60280", "Eur", "10-Nov-15", "1511", "B/Ctf", "6006", "VR MOB", "E MOBILE", "B2", "-98.48", "-98.48", nil], ["B2", "B. BANK    60280", "Eur", "11-Nov-15", "1511", "B/Ctf", "6004", "MON", "BERNARD BIGGINS", "B2", "-20", "-20", nil]]
    expected_bank = [["11/10/15", "WDL  ", "RCUR TIS00129758677", "DD EIRCOM TIS", "0", "98.48", "-489,421.79"], ["11/11/15", "WDL  ", "IE92BOFI90348878701288", "BERNARD BIGGINS", "93", "20", "-489,441.79"]]
    assert_equal @app.matching_client_debits.map {|i,v| v[:data][1..-1] }, expected_client, "list of client reconciled items is correct"
    assert_equal @app.matching_bank_debits.map {|v| v[:data][1..-1] }, expected_bank, "list of bank reconciled items is correct"
  end

  def test_reconciled_list
    @app.process_debits
    expected = [
      ["5/31/16", "WDL  \t", "3801", "Stop Cheque Charge", "0", "5", "-385,879.21"],
      ["B2", "B. BANK    60280", "Eur", "10-Nov-15", "1511", "B/Ctf", "6002", "COM", "EIR", "B2", "-98.48", "-98.48", nil],
      ["B2", "B. BANK    60280", "Eur", "18-Nov-15", "1511", "B/Ctf", "6005", "MON", "BAGGINS", "B2", "-20", "-20", nil],
      ["B2", "B. BANK    60280", "Eur", "31-May-16", "1605", "B/Ctf", "6087", "CHARGE", "STOP CHEQUE CHARGE", "B2", "5", "5", nil]
    ]
    actual = @app.unreconciled_debits_list.map {|i,v| v[:data][1..-1] }
    assert_empty actual - expected, "list of unreconciled items is correct"
  end

  def teardown
    @app = nil
  end
end