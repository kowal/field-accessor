module FieldAccessor
  class SimpleProxy

    attr_accessor :reader, :writer, :target

    def initialize(owner, target = nil)
      @owner = owner
      @target = target
      @reader = nil
      @writer = nil      
    end

    def self.create(owner, target = nil, &block)
      p = new(owner, target)
      p.instance_eval(&block)
      p
    end

    def read(&block)
      @reader = block
    end

    def write(&block)
      @writer = block
    end

    def read_value
      @reader.call
    end

    def write_value(v)
      @writer.call(v)
    end
  end

  def field_accessor(*attrs)
    attrs.each do |f| # f= :value
      
      p = "#{f}_proc".to_sym
      c = "#{f}_cache".to_sym
      
      attr_accessor p, c

      class_eval do
        def bind(field_desc, &block)
          field = field_desc.keys.first
          target = field_desc.values.first
          if block_given?
            send("#{field}_proc=", SimpleProxy.create(self, target, &block))
          end
        end

        # o.value_reader { }
        define_method("#{f}_reader") do |reader_proc|      
          prox = send("#{f}_proc") || SimpleProxy.new(self) # get or create proxy
          prox.reader = reader_proc
          send("#{f}_proc=", prox)
        end

        # o.value_writer { }
        define_method("#{f}_writer") do |writer_proc|      
          prox = send("#{f}_proc") || SimpleProxy.new(self) # get or create proxy
          prox.writer = writer_proc
          send("#{f}_proc=", prox)
        end
      end

      # def value() ... end
      define_method(f) do
        if send(c)
          x = send(c)
          return x.is_a?(Proc) ? x.call : x
        else
          gm = send(p)
          if gm
            gm.read_value          
          end
        end
      end

      # def value=(v) .. end
      define_method("#{f}=") do |v|
        begin
          sm = send(p)
          if sm
            x = sm.write_value(v)
            send("#{c}=", nil)
          else # proxy not set
            send("#{c}=", v)
          end
        rescue
          send("#{c}=", v)
        end
      end     

    end
   
  end
end
