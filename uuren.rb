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

    @id = nil
  end

  def start_tracking
    opened_slots = @db.get_first_value('SELECT COUNT(1) FROM uuren WHERE end_time IS NULL')[0]

    raise "Not expecting opened slots!" if opened_slots > 0
    @db.execute('INSERT INTO uuren (start_time) VALUES (?)', now)
    @id = @db.last_insert_row_id
  end

  def stop_tracking
    return if @id.nil?

    @db.execute('UPDATE uuren SET end_time = :end WHERE id = :id',
                 { end: now, id: @id })
  end

  def now
    Time.now.to_i
  end
end



store = TimeStore.new

begin
  store.start_tracking
  print('Starting...')
  $stdin.gets
rescue SystemExit, Interrupt
  store.stop_tracking
end

