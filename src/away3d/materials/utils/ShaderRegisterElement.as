package away3d.materials.utils
{
	/**
	 * A single register element (an entire register or a single register's component) used by the RegisterPool.
	 */
	public class ShaderRegisterElement
	{
		private var _regName : String;
		private var _index : int;
		private var _toStr : String;
		
		private static const COMPONENTS : Array = ["x", "y", "z", "w"];
		
		private static const SWIZZLE : uint = (0xE4 << 24);
		private static const TYPE_SHIFT : uint = 12;
		
		public static const A_TYPE : uint = 0;
		public static const C_TYPE : uint = 1;
		public static const T_TYPE : uint = 2;
		public static const O_TYPE : uint = 3;
		public static const V_TYPE : uint = 4;
		public static const S_TYPE : uint = 5;
		private static const TYPESSTR : Vector.<String> = new <String>[ "a", "c", "t", "o", "v", "s" ];
		
		internal var _component : int;
		private var _val : int;

		/**
		 * Creates a new ShaderRegisterElement object.
		 * @param regName The name of the register.
		 * @param index The index of the register.
		 * @param component The register's component, if not the entire register is represented.
		 */
		public function ShaderRegisterElement( type : uint, index : int, component : int = -1) {
			_component = component;
			_regName = regName;
			_index = index;
			
			_toStr = TYPESSTR[type];
			
			if( type == S_TYPE )
				_val = index;
			else
				_val = index + ( type << TYPE_SHIFT ) + SWIZZLE;
			
			if (_index >= 0 )
				_toStr += _index;
				
			if ( component > -1 ) {
				_toStr += "." + COMPONENTS[component];
				_val ^= ((1<<( component*2 ))^0xE4)<<24;
			}
		}

		/**
		 * Converts the register or the components AGAL string representation.
		 */
		public function toString() : String
		{
			return _toStr;
		}

		public function value() : uint
		{
			return _val;
		}

		/**
		 * The register's name.
		 */
		public function get regName() : String
		{
			return _regName;
		}

		/**
		 * The register's index.
		 */
		public function get index() : int
		{
			return _index;
		}

		/**
		 * The register's component, if not the entire register is represented.
		 */
	}
}
