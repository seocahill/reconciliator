require 'minitest/autorun'
require 'pry-rescue/minitest'
require_relative '../app'

class ChequeTest < Minitest::Test

  def setup
    @app = Reconciler.new
    @app.instance_variable_set(:@data_folder, __dir__ + "/")
    @app.store_records
  end

  def test_storage
    assert_equal @app.records.length, 15, "parse and store csv records in a hash"
  end

  def test_analyze
    @app.process_cheques
    assert_equal @app.cheque_ledger.length, 11, "allocated buckets"
    assert_equal @app.cheque_ledger[3120][:bank].length, 1
    assert_equal @app.cheque_ledger[3120][:client].length, 1
  end

  def test_single_reconciliation
    @app.process_cheques
    @app.reconcile_cheques
    bank_chq_id = @app.cheque_ledger[3120][:bank].first
    client_chq_id = @app.cheque_ledger[3120][:client].first
    assert_equal @app.records[bank_chq_id][:match_id], client_chq_id, "matched bank record"
    assert_equal @app.records[client_chq_id][:match_id], bank_chq_id, "matched client record"
  end

  def test_multiple_reconciliation
    # for cheques just take the first matching client record which is likely to be the correct one
    @app.process_cheques
    @app.reconcile_cheques
    bank_chq_id = @app.cheque_ledger[37880][:bank].first
    client_chq_id = @app.cheque_ledger[37880][:client].first
    assert_equal @app.records[bank_chq_id][:match_id], client_chq_id, "matched bank record"
    assert_equal @app.records[client_chq_id][:match_id], bank_chq_id, "matched client record"
  end

  def teardown
    @app = nil
  end
end