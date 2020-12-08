class Cielli
  class Slug < ::String
    Join = '-'

    def Slug.for(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}

      join = (options[:join] || options['join'] || Join).to_s

      string = args.flatten.compact.join(' ')

      tokens = string.scan(%r`[^\s#{ join }]+`)

      tokens.map! do |token|
        token.gsub(%r`[^\p{L}/.]`, '').downcase
      end

      tokens.map! do |token|
        token.gsub(%r`[/.]`, join * 2)
      end

      tokens.join(join)
    end
  end
end
