#!/usr/bin/env -S ruby -W

require 'sqlite3'

db = SQLite3::Database.new('uuren.db')

db.execute(<<-SQL)
  CREATE TABLE IF NOT EXISTS
  uuren
  (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    start_time INTEGER NOT NULL,
    end_time INTEGER
  )
SQL

opened_slots = db.get_first_value('SELECT COUNT(1) FROM uuren WHERE end_time IS NULL')[0]


raise "Not expecting opened slots!" if opened_slots > 0


id = nil
begin
  now = Time.now.to_i
  db.execute('INSERT INTO uuren (start_time) VALUES (?)', now)
  id = db.last_insert_row_id
  print('Starting...')
  $stdin.gets
rescue SystemExit, Interrupt
  unless id.nil?
    db.execute('UPDATE uuren SET end_time = :end WHERE id = :id',
               { end: Time.now.to_i, id: id })
  end
end

