package away3d.materials.methods {

	import com.instagal.regs.*;
	import away3d.arcane;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	import com.instagal.ShaderChunk;
	import com.instagal.Tex;

	use namespace arcane;

	public class HeightMapNormalMethod extends BasicNormalMethod
	{
		private var _worldXYRatio : Number;
		private var _worldXZRatio : Number;

		public function HeightMapNormalMethod(heightMap : Texture2DBase, worldWidth : Number, worldHeight : Number, worldDepth : Number)
		{
			super();
			normalMap = heightMap;
			_worldXYRatio = worldWidth/worldHeight;
			_worldXZRatio = worldDepth/worldHeight;
		}

		override arcane function initConstants(vo : MethodVO) : void
		{
			var index : int = vo.fragmentConstantsIndex;
			var data : Vector.<Number> = vo.fragmentData;
			data[index] = 1/normalMap.width;
			data[index+1] = 1/normalMap.height;
			data[index+2] = 0;
			data[index+3] = 1;
			data[index+4] = _worldXYRatio;
			data[index+5] = _worldXZRatio;
		}

		override arcane function get tangentSpace() : Boolean
		{
			return false;
		}

		override public function copyFrom(method : ShadingMethodBase) : void
		{
		}

		arcane override function getFragmentCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var dataReg : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg2 : ShaderRegisterElement = regCache.getFreeFragmentConstant();
			_normalTextureRegister = regCache.getFreeTextureReg();
			vo.texturesIndex = _normalTextureRegister.index;
			vo.fragmentConstantsIndex = dataReg.index*4;
			
			var code : ShaderChunk = new ShaderChunk();
			
			var tgt : uint = targetReg.value();
			
		
			getTexSampleCode(code, vo, targetReg, _normalTextureRegister, _uvFragmentReg, Tex.CLAMP, _texture.samplerType);
			code.add(  temp.value()      , _uvFragmentReg.value(),dataReg.value() ^xz);
			
			getTexSampleCode(code, vo, temp, _normalTextureRegister, temp, Tex.CLAMP, _texture.samplerType);
			code.sub(  tgt  ^x   , tgt ^x, temp.value() ^x);
			code.add(  temp.value()      , _uvFragmentReg.value() ,  dataReg.value() ^zyz);
			
			getTexSampleCode(code, vo, temp, _normalTextureRegister, temp, Tex.CLAMP, _texture.samplerType);
			code.sub(  tgt  ^z   , tgt ^z, temp.value() ^x);
			code.mov(  tgt  ^y   , dataReg.value() ^w);
			code.mul(  tgt  ^xz  , tgt ^xz, dataReg2.value() ^xy);
			code.nrm(  tgt  ^xyz , tgt ^xyz);
			
			return code;
		}
	}
}
