#!/usr/bin/env -S ruby -W

require 'sqlite3'


class TimeStore
  def initialize
    @db = SQLite3::Database.new('uuren.db')

    @db.execute(<<-SQL)
      CREATE TABLE IF NOT EXISTS
      hours
      (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        seconds INTEGER NOT NULL
      )
    SQL
  end

  def add_to_today(seconds)
    t = today
    @db.execute('INSERT OR IGNORE INTO hours (date, seconds) VALUES (?, 0)', t)
    @db.execute('UPDATE hours SET seconds = seconds + ? WHERE date = ?',
                 [seconds, t])
  end

  def yesterday_time
    day_elapsed(today(-1))
  end

  def today_time
    day_elapsed(today)
  end

  def day_elapsed(date)
    @db.get_first_value('SELECT seconds FROM hours WHERE date = ?', date) || 0
  end

  def today(delta=0)
    (now + delta * 86400).strftime('%Y-%m-%d')
  end

  def now
    Time.now
  end
end


def format_elapsed(label, elapsed)
  elapsed_str = Time.at(elapsed).utc.strftime('%H:%M:%S')
  "#{label}: #{elapsed_str}"
end

store = TimeStore.new

last_update = store.now
begin
  puts('Tracking time...')
  sleep_time = 60
  puts(format_elapsed('Yesterday', store.yesterday_time))
  while true do
    print("\r%s" % format_elapsed('Today    ', store.today_time))

    sleep(sleep_time)
    store.add_to_today(sleep_time)

    last_update = Time.now
  end
rescue SystemExit, Interrupt
  unless last_update.nil?
    store.add_to_today((store.now - last_update).to_i)
  end
end

