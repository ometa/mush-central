# Copyright (C) 2017 Devin Breen
# This file is part of dogtag <https://github.com/chiditarod/dogtag>.
#
# dogtag is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# dogtag is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with dogtag.  If not, see <http://www.gnu.org/licenses/>.
redis_url = ENV['REDIS_URL'] || "redis://127.0.0.1:6379/0"

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
  config.failures_max_count = false # no limit on number of failing jobs in flight
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
