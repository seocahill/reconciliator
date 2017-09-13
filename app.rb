#!/usr/bin/env ruby

require 'csv'
require 'pry'
require 'pry-rescue'
require 'securerandom'
require 'axlsx'
require_relative 'lib/cheques'
require_relative 'lib/debits'
require_relative 'lib/helpers'
require_relative 'lib/lodgements'
require_relative 'lib/tots'

class Reconciler
  include Cheques
  include Debits
  include Helpers
  include Lodgements
  include Tots

  attr_reader :records, :cheque_ledger, :client_debits

  def initialize
    @records = {}
    @cheque_ledger = {}
    @value_lookup = {}
    @date_lookup = {}
    @tots = { "bank": {}, "client": {} }
    @data_folder = ENV["HOME"] + ARGV[0]
    @excel_obj = Axlsx::Package.new
  end

  def perform
    store_records
    analyze_records
    print_results
  end

  def store_records
    @bank_items_header, *bank_items = CSV.read(@data_folder + "bank-transactions.csv")
    @client_items_header, *client_items = CSV.read(@data_folder + "client-records.csv")
    bank_sheet = @excel_obj.workbook.add_worksheet(:name => "Bank transactions")
    client_sheet = @excel_obj.workbook.add_worksheet(:name => "Client records")
    bank_items.each { |row| add_record(row, 'bank'); bank_sheet.add_row row }
    client_items.each { |row| add_record(row, 'client'); client_sheet.add_row row }
  end

  def analyze_records
    # process_lodgements
    process_debits
    process_cheques
  end

  def print_results
    # print_lodgements
    print_debits
    print_cheques
    print_unreconciled_cheques
    print_unreconciled_debits
    print_tots
    @excel_obj.use_shared_strings = true
    @excel_obj.serialize(@data_folder + 'ruane-const-bank-rec.xlsx')
  end

  private

  def add_record(row, owner)
    id = SecureRandom.uuid
    row.unshift(id)
    type = transaction_type(row, owner)
    @records[id] = { 
      data: row, 
      owner: owner, 
      match_id: nil,
      type: type,
      date: date_as_integer(row, owner)
    }
    add_to_value_lookup(id, row, owner)
    add_to_date_lookup(id, row, owner)
    add_tot(row, owner, type)
  end

  def add_to_value_lookup(id, data, owner)
    rounded_value = row_amount(data, owner).round
    (@value_lookup[rounded_value] ||= []) << id
  end

  def add_to_date_lookup(id, data, owner)
    date = date_as_integer(data, owner)
    (@date_lookup[date] ||= []) << id
  end

  def bank_total
    @bank_reconciled.map { |i| str_to_num(i[5]) }.inject(&:+)
  end

  def client_total 
    @client_reconciled.map { |i| str_to_num(i[11]) }.inject(&:+)
  end
end

Pry.rescue do
  Reconciler.new.perform
end