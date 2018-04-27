# frozen_string_literal: true

# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

# This class is used by NewRelic::Agent.set_sql_obfuscator to chain multiple
# obfuscation blocks when not using the default :replace action
class NewRelic::ChainedCall
  def initialize(block1, block2)
    @block1 = block1
    @block2 = block2
  end

  def call(sql)
    sql = @block1.call(sql)
    @block2.call(sql)
  end
end
