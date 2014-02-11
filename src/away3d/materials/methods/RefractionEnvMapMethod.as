package away3d.materials.methods
{
	import com.instagal.Tex;
	import com.instagal.ShaderChunk;
	import com.instagal.regs.*;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.CubeTextureBase;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class RefractionEnvMapMethod extends EffectMethodBase
	{
		private var _envMap : CubeTextureBase;

		private var _dispersionR : Number = 0;
		private var _dispersionG : Number = 0;
		private var _dispersionB : Number = 0;
		private var _useDispersion : Boolean;
		private var _refractionIndex : Number;
		private var _alpha : Number = 1;

		// example values for dispersion: dispersionR : Number = -0.03, dispersionG : Number = -0.01, dispersionB : Number = .0015
		public function RefractionEnvMapMethod(envMap : CubeTextureBase, refractionIndex : Number = .9, dispersionR : Number = 0, dispersionG : Number = 0, dispersionB : Number = 0)
		{
			super();
			_envMap = envMap;
			_dispersionR = dispersionR;
			_dispersionG = dispersionG;
			_dispersionB = dispersionB;
			_useDispersion = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			_refractionIndex = refractionIndex;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			var index : int = vo.fragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index+4] = 1;
			data[index+5] = 0;
			data[index+7] = 1;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsNormals = true;
			vo.needsView = true;
		}

		public function get refractionIndex() : Number
		{
			return _refractionIndex;
		}

		public function set refractionIndex(value : Number) : void
		{
			_refractionIndex = value;
		}

		public function get dispersionR() : Number
		{
			return _dispersionR;
		}

		public function set dispersionR(value : Number) : void
		{
			_dispersionR = value;

			var useDispersion : Boolean = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			if (_useDispersion != useDispersion) {
				invalidateShaderProgram();
				_useDispersion = useDispersion;
			}
		}

		public function get dispersionG() : Number
		{
			return _dispersionG;
		}

		public function set dispersionG(value : Number) : void
		{
			_dispersionG = value;

			var useDispersion : Boolean = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			if (_useDispersion != useDispersion) {
				invalidateShaderProgram();
				_useDispersion = useDispersion;
			}
		}

		public function get dispersionB() : Number
		{
			return _dispersionB;
		}

		public function set dispersionB(value : Number) : void
		{
			_dispersionB = value;

			var useDispersion : Boolean = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
			if (_useDispersion != useDispersion) {
				invalidateShaderProgram();
				_useDispersion = useDispersion;
			}
		}

		public function get alpha() : Number
		{
			return _alpha;
		}

		public function set alpha(value : Number) : void
		{
			_alpha = value;
		}

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var index : int = vo.fragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index] = _dispersionR + _refractionIndex;
			if (_useDispersion) {
				data[index+1] = _dispersionG + _refractionIndex;
				data[index+2] = _dispersionB + _refractionIndex;
			}
			data[index+3] = _alpha;
			stage3DProxy.setTextureAt(vo.texturesIndex, _envMap.getTextureForStage3D(stage3DProxy));
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			// todo: data2.x could use common reg, so only 1 reg is used
			var data : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var data2 : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var code : ShaderChunk = new ShaderChunk();
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var refractionDir : ShaderRegisterElement;
			var refractionColor : ShaderRegisterElement;
			var temp : ShaderRegisterElement;

			vo.texturesIndex = cubeMapReg.index;
			vo.fragmentConstantsIndex = data.index*4;

			refractionDir = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(refractionDir, 1);
			refractionColor = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(refractionColor, 1);

			temp = regCache.getFreeFragmentVectorTemp();
			
			
			var vdr : uint = _viewDirFragmentReg.value();
			var nrm : uint = _normalFragmentReg.value();
			var rfc : uint = refractionDir.value();
			var tgr : uint = targetReg.value();
			var tmp : uint = temp.value();
			var dt1 : uint = data.value();
			var dt2 : uint = data2.value();
			var smp : uint = cubeMapReg.value() | Tex.CUBE| (vo.useSmoothTextures? Tex.LINEAR: Tex.NEAREST ) | Tex.MIPLINEAR| Tex.CLAMP;

			code.neg( vdr ^xyz, vdr ^xyz  );
			code.dp3( tmp ^x,   vdr ^xyz, nrm ^xyz);
			code.mul( tmp ^w,   tmp ^x,   tmp ^x);
			code.sub( tmp ^w,   dt2 ^x,   tmp ^w);
			code.mul( tmp ^w,   dt1 ^x,   tmp ^w);
			code.mul( tmp ^w,   dt1 ^x,   tmp ^w);
			code.sub( tmp ^w,   dt2 ^x,   tmp ^w);
			code.sqt( tmp ^y,   tmp ^w);  
			code.mul( tmp ^x,   dt1 ^x,   tmp ^x);
			code.add( tmp ^x,   tmp ^x,   tmp ^y);
			code.mul( tmp ^xyz, tmp ^x,   nrm ^xyz);
			code.mul( rfc ,     dt1 ^x,   vdr );
			code.sub( rfc ^xyz, rfc ^xyz, tmp ^xyz);
			code.nrm( rfc ^xyz, rfc ^xyz);

			code.tex( refractionColor.value(), rfc, smp );

			if (_useDispersion) {
				// GREEN

				code.dp3( tmp ^x,   vdr ^xyz,  nrm ^xyz);
				code.mul( tmp ^w,   tmp ^x,    tmp ^x);
				code.sub( tmp ^w,   dt2 ^x,    tmp ^w);
				code.mul( tmp ^w,   dt1 ^y,    tmp ^w);
				code.mul( tmp ^w,   dt1 ^y,    tmp ^w);
				code.sub( tmp ^w,   dt2 ^x,    tmp ^w);
				code.sqt( tmp ^y,   tmp ^w);  
				code.mul( tmp ^x,   dt1 ^y,    tmp ^x);
				code.add( tmp ^x,   tmp ^x,    tmp ^y);
				code.mul( tmp ^xyz, tmp ^x,    nrm ^xyz);
				code.mul( rfc ,     dt1 ^y,    vdr );
				code.sub( rfc ^xyz, rfc ^xyz,  tmp ^xyz);
				code.nrm( rfc ^xyz, rfc ^xyz );
				code.tex( tmp ,     rfc , smp);
				code.mov( refractionColor.value() ^y, tmp ^y );



				// BLUE

				code.dp3( tmp ^x,   vdr ^xyz,  nrm ^xyz);
				code.mul( tmp ^w,   tmp ^x,    tmp ^x);
				code.sub( tmp ^w,   dt2 ^x,    tmp ^w);
				code.mul( tmp ^w,   dt1 ^z,    tmp ^w);
				code.mul( tmp ^w,   dt1 ^z,    tmp ^w);
				code.sub( tmp ^w,   dt2 ^x,    tmp ^w);
				code.sqt( tmp ^y,   tmp ^w);  
				code.mul( tmp ^x,   dt1 ^z,    tmp ^x);
				code.add( tmp ^x,   tmp ^x,    tmp ^y);
				code.mul( tmp ^xyz, tmp ^x,    nrm ^xyz);
				code.mul( rfc ,     dt1 ^z,    vdr );
				code.sub( rfc ^xyz, rfc ^xyz,  tmp ^xyz);
				code.nrm( rfc ^xyz, rfc ^xyz);
				code.tex( tmp , rfc , smp );
				code.mov( refractionColor.value() ^z, tmp ^z );
			}

			regCache.removeFragmentTempUsage(refractionDir);

			code.sub( refractionColor.value()^xyz, refractionColor.value() ^xyz, tgr ^xyz);
			code.mul( refractionColor.value()^xyz, refractionColor.value() ^xyz, dt1 ^w);
			code.add( tgr ^xyz, tgr ^xyz, refractionColor.value() ^xyz );
			
			regCache.removeFragmentTempUsage(refractionColor);

			// restore
			code.neg(  vdr ^xyz, vdr ^xyz );

			return code;
		}
	}
}
