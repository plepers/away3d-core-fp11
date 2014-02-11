package away3d.materials.methods
{
	import com.instagal.regs.*;
	import away3d.arcane;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import com.instagal.ShaderChunk;

	use namespace arcane;

	/**
	 * DepthDiffuseMethod provides a debug method to visualise depth maps
	 */
	public class DepthDiffuseMethod extends BasicDiffuseMethod
	{
		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function DepthDiffuseMethod()
		{
			super();
		}


		override arcane function initConstants(vo : MethodVO) : void
		{
			var data : Vector.<Number> = vo.fragmentData;
			var index : int = vo.fragmentConstantsIndex;
			data[index] = 1.0;
			data[index+1] = 1/255.0;
			data[index+2] = 1/65025.0;
			data[index+3] = 1/16581375.0;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var code : ShaderChunk = new ShaderChunk();
			var temp : ShaderRegisterElement;
			var decReg : ShaderRegisterElement;
			var tr : uint = targetReg.value();

			if (!_useTexture) throw new Error("DepthDiffuseMethod requires texture!");

			// incorporate input from ambient
			if (vo.numLights > 0) {
				if (_shadowRegister)
					code.mul( _totalLightColorReg.value() ^xyz, _totalLightColorReg.value() ^xyz,  _shadowRegister.value() ^w );
				
				code.add( tr ^xyz, _totalLightColorReg.value() ^xyz, tr ^xyz );
				code.sat( tr ^xyz, tr ^xyz);
				regCache.removeFragmentTempUsage(_totalLightColorReg);
			}

			temp = vo.numLights > 0 ? regCache.getFreeFragmentVectorTemp() : targetReg;
			var tp : uint = temp.value();

			_diffuseInputRegister = regCache.getFreeTextureReg();
			vo.texturesIndex = _diffuseInputRegister.index;
			decReg = regCache.getFreeFragmentConstant();
			vo.fragmentConstantsIndex = decReg.index*4;
			getTexSampleCode(code, vo, temp, _diffuseInputRegister, null, null, _texture.samplerType);
			code.dp4( tp ^x,   tp , decReg.value() );
			code.mov( tp ^yzw, tp ^x );

			if (vo.numLights == 0)
				return code;

			code.mul( tr ^xyz, 	tp ^xyz, tr ^xyz );
			code.mov( tr ^w, 	tp ^w );

			return code;
		}
	}
}
