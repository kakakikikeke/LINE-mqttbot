# frozen_string_literal: true

require 'json'

# 応答設定をファイルから読み込むリポジトリ
class AnswerRepository
  def initialize(path)
    @path = path
  end

  def load
    JSON.parse(File.read(@path))
  end
end
