package away3d.materials.methods
{
	import com.instagal.regs.*;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class RimLightMethod extends EffectMethodBase
	{
		public static const ADD : String = "add";
		public static const MULTIPLY : String = "multiply";
		public static const MIX : String = "mix";

		private var _color : uint;
		private var _blend : String;
		private var _colorR : Number;
		private var _colorG : Number;
		private var _colorB : Number;
		private var _strength : Number;
		private var _power : Number;

		public function RimLightMethod(color : uint = 0xffffff, strength : Number = .4, power : Number = 2, blend : String = "mix")
		{
			super();
			_blend = blend;
			_strength = strength;
			_power = power;
			this.color = color;
		}


		override arcane function initConstants(vo : MethodVO) : void
		{
			vo.fragmentData[vo.fragmentConstantsIndex+3] = 1;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsNormals = true;
			vo.needsView = true;
		}

		public function get color() : uint
		{
			return _color;
		}

		public function set color(value : uint) : void
		{
			_color = value;
			_colorR = ((value >> 16) & 0xff)/0xff;
			_colorG = ((value >> 8) & 0xff)/0xff;
			_colorB = (value & 0xff)/0xff;
		}

		public function get strength() : Number
		{
			return _strength;
		}

		public function set strength(value : Number) : void
		{
			_strength = value;
		}

		public function get power() : Number
		{
			return _power;
		}

		public function set power(value : Number) : void
		{
			_power = value;
		}

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var index : int = vo.fragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index] = _colorR;
			data[index+1] = _colorG;
			data[index+2] = _colorB;
			data[index+4] = _strength;
			data[index+5] = _power;
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var dataRegister : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataRegister2 : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : ShaderChunk = new ShaderChunk();
			vo.fragmentConstantsIndex = dataRegister.index*4;
			
			var vdr : uint = _viewDirFragmentReg.value();
			var nrm : uint = _normalFragmentReg.value();
			var tgr : uint = targetReg.value();
			var tmp : uint = temp.value();
			var dt1 : uint = dataRegister.value();
			var dt2 : uint = dataRegister2.value();
			
			code.dp3( tmp ^x,    vdr ^xyz, nrm ^xyz	);
			code.sat( tmp ^x,    tmp ^x				);
			code.sub( tmp ^x,    dt1 ^w,   tmp ^x	);
			code.pow( tmp ^x,    tmp ^x,   dt2 ^y	);
			code.mul( tmp ^x,    tmp ^x,   dt2 ^x	);
			code.sub( tmp ^x,    dt1 ^w,   tmp ^x	);
			code.mul( tgr ^xyz,  tgr ^xyz, tmp ^x	);
			code.sub( tmp ^w,    dt1 ^w,   tmp ^x	);

			if (_blend == ADD) {
				code.mul( tmp ^xyz,  tmp ^w,   dt1 ^xyz	);
				code.add( tgr ^xyz,  tgr ^xyz, tmp ^xyz	);
			}
			else if (_blend == MULTIPLY) {
				code.mul( tmp ^xyz,  tmp ^w,   dt1 ^xyz	);
				code.mul( tgr ^xyz,  tgr ^xyz, tmp ^xyz	);
			}
			else {
				code.sub( tmp ^xyz,  dt1 ^xyz, tgr ^xyz	);
				code.mul( tmp ^xyz,  tmp ^xyz, tmp ^w	);
				code.add( tgr ^xyz,  tgr ^xyz, tmp ^xyz	);
			}

			return code;
		}
	}
}
