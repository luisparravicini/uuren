#!/usr/bin/env -S ruby -W

require 'sqlite3'


class TimeStore
  def initialize
    @db = SQLite3::Database.new('uuren.db')

    @db.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS
      uuren
      (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER
      )
    SQL

    @slot_id = nil
  end

  def start_tracking
    @db.execute('INSERT INTO uuren (start_time, end_time) VALUES (:start, :end)',
                { start: now, end: now })
    @slot_id = @db.last_insert_row_id
  end

  def update_tracking
    return if @slot_id.nil?

    @db.execute('UPDATE uuren SET end_time = :end WHERE id = :id',
                 { end: now, id: @slot_id })
  end

  def now
    Time.now.to_i
  end
end



store = TimeStore.new

begin
  store.start_tracking
  print('Tracking time...')
  while true do
    sleep(60)
    store.update_tracking
  end
rescue SystemExit, Interrupt
  store.update_tracking
end

