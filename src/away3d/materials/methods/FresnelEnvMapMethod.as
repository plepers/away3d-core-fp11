package away3d.materials.methods
{
	import com.instagal.regs.*;
	import com.instagal.Tex;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.CubeTextureBase;

	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class FresnelEnvMapMethod extends EffectMethodBase
	{
		private var _cubeTexture : CubeTextureBase;
		private var _fresnelPower : Number = 5;
		private var _normalReflectance : Number = 0;
		private var _alpha : Number;

		public function FresnelEnvMapMethod(envMap : CubeTextureBase, alpha : Number = 1)
		{
			super();
			_cubeTexture = envMap;
			_alpha = alpha;
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsNormals = true;
			vo.needsView = true;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			vo.fragmentData[vo.fragmentConstantsIndex+3] = 1;
		}

		public function get fresnelPower() : Number
		{
			return _fresnelPower;
		}

		public function set fresnelPower(value : Number) : void
		{
			_fresnelPower = value;
		}

		/**
		 * The cube environment map to use for the diffuse lighting.
		 */
		public function get envMap() : CubeTextureBase
		{
			return _cubeTexture;
		}

		public function set envMap(value : CubeTextureBase) : void
		{
			_cubeTexture = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
		}

		public function get alpha() : Number
		{
			return _alpha;
		}

		public function set alpha(value : Number) : void
		{
			_alpha = value;
		}

		/**
		 * The minimum amount of reflectance, ie the reflectance when the view direction is normal to the surface or light direction.
		 */
		public function get normalReflectance() : Number
		{
			return _normalReflectance;
		}

		public function set normalReflectance(value : Number) : void
		{
			_normalReflectance = value;
		}

		arcane override function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var data : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			data[index] = _alpha;
			data[index+1] = _normalReflectance;
			data[index+2] = _fresnelPower;
			stage3DProxy.setTextureAt(vo.texturesIndex, _cubeTexture.getTextureForStage3D(stage3DProxy));
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var dataRegister : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code : ShaderChunk = new ShaderChunk();
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			vo.texturesIndex = cubeMapReg.index;
			vo.fragmentConstantsIndex = dataRegister.index*4;
			
			var tmp : uint = temp.value();
			var vdr : uint = _viewDirFragmentReg.value();
			var nrm : uint = _normalFragmentReg.value();
			var ddr : uint = dataRegister.value();
			var tgr : uint = targetReg.value();
			
			// r = V - 2(V.N)*N
			code.dp3( tmp ^w	, vdr ^xyz	, nrm 	^xyz		);
			code.add( tmp ^w	, tmp ^w  	, tmp 	^w		);
			code.mul( tmp ^xyz	, nrm ^xyz	, tmp 	^w		);
			code.sub( tmp ^xyz	, vdr ^xyz	, tmp 	^xyz		);
			code.neg( tmp ^xyz	, tmp ^xyz );
			code.tex( tmp 		, tmp 		, cubeMapReg |Tex.CUBE | (vo.useSmoothTextures? Tex.LINEAR : Tex.NEAREST ) | Tex.MIPLINEAR |Tex.CLAMP);
			code.sub( tmp 		, tmp 		, tgr 												);
			code.dp3( vdr ^w	, vdr ^xyz	, nrm 	^xyz); 
            code.sub( vdr ^w	, ddr ^w	, vdr 	^w);   
			code.pow( vdr ^w	, vdr ^w	, ddr 	^z);   
			code.sub( nrm ^w	, ddr ^w	, vdr 	^w);   
			code.mul( nrm ^w	, ddr ^y	, nrm 	^w);   
			code.add( vdr ^w	, vdr ^w	, nrm 	^w);   
			code.mul( vdr ^w	, ddr ^x	, vdr 	^w);
			code.mul( tmp 		, tmp 		, vdr 	^w		);
			code.add( tgr ^xyzw	, tgr ^xyzw	, tmp 	^xyzw	);


			return code;
		}
	}
}
