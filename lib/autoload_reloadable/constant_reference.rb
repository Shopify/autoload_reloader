# frozen_string_literal: true

module AutoloadReloadable
  ConstantReference = Struct.new(:parent, :name, :filename, :path_root) do
    def directory?
      !filename.end_with?('.rb')
    end
  end
  private_constant :ConstantReference
end
