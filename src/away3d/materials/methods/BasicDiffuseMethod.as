package away3d.materials.methods {

	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;
	import com.instagal.ShaderChunk;
	import com.instagal.Tex;
	import com.instagal.regs.*;
	import flash.display3D.Context3D;

	use namespace arcane;

	/**
	 * BasicDiffuseMethod provides the default shading method for Lambert (dot3) diffuse lighting.
	 */
	public class BasicDiffuseMethod extends LightingMethodBase
	{
		arcane var _useDiffuseTexture : Boolean;
		
		protected var _useTexture : Boolean;
		arcane var _totalLightColorReg : ShaderRegisterElement;

		// TODO: are these registers at all necessary to be members?
		protected var _diffuseInputRegister : ShaderRegisterElement;

		protected var _texture : Texture2DBase;
		private var _diffuseColor : uint = 0xffffff;
		private var _diffuseR : Number = 1, _diffuseG : Number = 1, _diffuseB : Number = 1, _diffuseA : Number = 1;
		protected var _shadowRegister : ShaderRegisterElement;

		protected var _alphaThreshold : Number = 0;

		/**
		 * Creates a new BasicDiffuseMethod object.
		 */
		public function BasicDiffuseMethod()
		{
			super();
		}

		override arcane function initVO(vo : MethodVO) : void
		{
			vo.needsUV = _useTexture;
			vo.needsNormals = vo.numLights > 0;
		}

		public function generateMip(stage3DProxy : Stage3DProxy):void
		{
			if (_useTexture)
			{
				_texture.getTextureForStage3D(stage3DProxy);
			}
		}

		/**
		 * The alpha component of the diffuse reflection.
		 */
		public function get diffuseAlpha() : Number
		{
			return _diffuseA;
		}

		public function set diffuseAlpha(value : Number) : void
		{
			_diffuseA = value;
		}

		/**
		 * The color of the diffuse reflection when not using a texture.
		 */
		public function get diffuseColor() : uint
		{
			return _diffuseColor;
		}

		public function set diffuseColor(diffuseColor : uint) : void
		{
			_diffuseColor = diffuseColor;
			updateDiffuse();
		}

		/**
		 * The bitmapData to use to define the diffuse reflection color per texel.
		 */
		public function get texture() : Texture2DBase
		{
			return _texture;
		}

		public function set texture(value : Texture2DBase) : void
		{
			_useTexture = Boolean(value);
			_texture = value;
			if (!value || !_useTexture) invalidateShaderProgram();
		}

		/**
		 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
		 * invisible or entirely opaque, often used with textures for foliage, etc.
		 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
		 */
		public function get alphaThreshold() : Number
		{
			return _alphaThreshold;
		}

		public function set alphaThreshold(value : Number) : void
		{
			if (value < 0) value = 0;
			else if (value > 1) value = 1;
			if (value == _alphaThreshold) return;

			if (value == 0 || _alphaThreshold == 0)
				invalidateShaderProgram();

			_alphaThreshold = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
			_texture = null;
		}

		/**
		 * Copies the state from a BasicDiffuseMethod object into the current object.
		 */
		override public function copyFrom(method : ShadingMethodBase) : void
		{
			var diff : BasicDiffuseMethod = BasicDiffuseMethod(method);
			alphaThreshold = diff.alphaThreshold;
			texture = diff.texture;
			diffuseAlpha = diff.diffuseAlpha;
			diffuseColor = diff.diffuseColor;
		}

		arcane override function cleanCompilationData() : void
		{
			super.cleanCompilationData();
			_shadowRegister = null;
			_totalLightColorReg = null;
			_diffuseInputRegister = null;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPreLightingCode(vo : MethodVO, regCache : ShaderRegisterCache) : ShaderChunk
		{

			if (vo.numLights > 0) {
				_totalLightColorReg = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(_totalLightColorReg, 1);
			}

			return null;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentCodePerLight(vo : MethodVO, lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : ShaderChunk
		{
			var code : ShaderChunk = new ShaderChunk();
			var t : ShaderRegisterElement;

			// write in temporary if not first light, so we can add to total diffuse colour
			if (lightIndex > 0) {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			else {
				t = _totalLightColorReg;
			}
			var tr : uint = t.value();
//			code += "dp3 " + t + ".x, " + lightDirReg + ".xyz, " + _normalFragmentReg + ".xyz\n" +
//					"sat " + t + ".w, " + t + ".x\n" +
//				// attenuation
//					"mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";
			code.dp3( tr ^ x, lightDirReg.value() ^ xyz, _normalFragmentReg.value() ^ xyz );
			code.sat( tr ^ w, tr ^ x );
			code.mul( tr ^ w, tr ^ w,  lightDirReg.value()^w );

			if (_modulateMethod != null) _modulateMethod(code, vo, t, regCache);

			code.mul( tr , tr ^ w, lightColReg.value() );


			if (lightIndex > 0) {
				code.add( _totalLightColorReg.value() ^ xyz, _totalLightColorReg.value() ^ xyz, tr ^ xyz );
				regCache.removeFragmentTempUsage(t);
			}

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerProbe(vo : MethodVO, lightIndex : int, cubeMapReg : ShaderRegisterElement, weightRegister : uint, regCache : ShaderRegisterCache) : ShaderChunk
		{
			var code : ShaderChunk = new ShaderChunk();
			var t : ShaderRegisterElement;

			// write in temporary if not first light, so we can add to total diffuse colour
			if (lightIndex > 0) {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}
			else {
				t = _totalLightColorReg;
			}
			var tr : uint = t.value();

			code.tex( tr, _normalFragmentReg.value(), cubeMapReg.value() | Tex.CUBE | Tex.LINEAR | Tex.MIPLINEAR );
			code.mul( tr, tr, weightRegister );

//			if (_modulateMethod != null) code += _modulateMethod(t, regCache);

//			code += "mul " + t + ".xyz, " + t + ".xyz, " + t + ".w\n";

			if (lightIndex > 0) {
				code.add( _totalLightColorReg.value() ^ xyz, _totalLightColorReg.value() ^ xyz, tr ^ xyz );
				regCache.removeFragmentTempUsage(t);
			}

			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPostLightingCode(vo : MethodVO, regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : ShaderChunk
		{
			var code : ShaderChunk = new ShaderChunk();
			var t : ShaderRegisterElement;
			var cutOffReg : ShaderRegisterElement;

			// incorporate input from ambient
			if (vo.numLights > 0) {
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
				
				if (_shadowRegister)
					code.mul(  _totalLightColorReg.value() ^ xyz, _totalLightColorReg.value() ^ xyz, _shadowRegister.value() ^ w );
			} else {
				t = targetReg;
			}
			var tr : uint = t.value();
			var treg : uint = targetReg.value();

			if (_useTexture) {
				_diffuseInputRegister = regCache.getFreeTextureReg();
				vo.texturesIndex = _diffuseInputRegister.index;
				getTexSampleCode(code, vo, t, _diffuseInputRegister, null, 0, _texture.samplerType);
				if (_alphaThreshold > 0) {
					cutOffReg = regCache.getFreeFragmentConstant();
					vo.fragmentConstantsIndex = cutOffReg.index*4;
					code.sub( tr ^ w, tr^w, cutOffReg.value() ^ x );
					code.kil( tr ^ w );
					code.add( tr ^ w, tr^w, cutOffReg.value() ^ x );
				}
			}
			else {
				_diffuseInputRegister = regCache.getFreeFragmentConstant();
				vo.fragmentConstantsIndex = _diffuseInputRegister.index*4;
				code.mov( tr, _diffuseInputRegister.value() );
			}

			if (vo.numLights == 0)
				return code;
			
			var tlr : uint = _totalLightColorReg.value();
			if (_useDiffuseTexture) {
				code.sat( tlr ^ xyz, tlr ^xyz );
				code.mul( tr ^xyz, tr ^ xyz, tlr ^ xyz );
				code.mul( tlr  ^ xyz, treg  ^ xyz, tlr ^ xyz);
				code.sub( treg  ^ xyz, treg ^ xyz, tlr ^ xyz);
				code.add( treg ^ xyz, tr  ^ xyz,  treg ^ xyz);
			} else {
				code.add( treg ^ xyz, tlr ^xyz, treg ^xyz);
				code.sat( treg ^ xyz, treg^xyz);
				code.mul( treg ^ xyz, tr  ^xyz, treg ^ xyz); 
				code.mov( treg ^ w  , tr  ^w ); 
			}

			regCache.removeFragmentTempUsage(_totalLightColorReg);
			regCache.removeFragmentTempUsage(t);
			
			return code;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(vo : MethodVO, stage3DProxy : Stage3DProxy) : void
		{
			var context : Context3D = stage3DProxy._context3D;


			if (_useTexture) {
				stage3DProxy.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
				if (_alphaThreshold > 0)
					vo.fragmentData[vo.fragmentConstantsIndex] = _alphaThreshold;
			}
			else {
				var index : int = vo.fragmentConstantsIndex;
				var data : Vector.<Number> = vo.fragmentData;
				data[index] = _diffuseR;
				data[index+1] = _diffuseG;
				data[index+2] = _diffuseB;
				data[index+3] = _diffuseA;
			}
		}


		/**
		 * Updates the diffuse color data used by the render state.
		 */
		private function updateDiffuse() : void
		{
			_diffuseR = ((_diffuseColor >> 16) & 0xff) / 0xff;
			_diffuseG = ((_diffuseColor >> 8) & 0xff) / 0xff;
			_diffuseB = (_diffuseColor & 0xff) / 0xff;
		}

		arcane function set shadowRegister(value : ShaderRegisterElement) : void
		{
			_shadowRegister = value;
		}
	}
}
