package away3d.materials.passes {

	import com.instagal.dump.Dump;
	import com.instagal.regs.*;
	import com.instagal.Shader;
	import com.instagal.ShaderChunk;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.events.ShadingMethodEvent;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightProbe;
	import away3d.lights.PointLight;
	import away3d.materials.LightSources;
	import away3d.materials.MaterialBase;
	import away3d.materials.lightpickers.LightPickerBase;
	import away3d.materials.methods.BasicAmbientMethod;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicNormalMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.methods.ColorTransformMethod;
	import away3d.materials.methods.EffectMethodBase;
	import away3d.materials.methods.MethodVO;
	import away3d.materials.methods.ShadingMethodBase;
	import away3d.materials.methods.ShadowMapMethodBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * DefaultScreenPass is a shader pass that uses shader methods to compile a complete program.
	 *
	 * @see away3d.materials.methods.ShadingMethodBase
	 */

	// TODO: Remove compilation from this class, gets messy. Only perform rendering here.
	public class DefaultScreenPass extends MaterialPassBase
	{
		
		private var _logmap:  Array = [
//			"@mat/juke/LightGlass"	
//			"HelpPanel_bgmat",
//			"optPanelMat [nissan.cc3d.desktop_v1.view.d3::ColorsPanel]"
		];
		
		
		
//		private var _cameraPositionData : Vector.<Number> = Vector.<Number>([0, 0, 0, 1]);
//		private var _lightData : Vector.<Number>;
//		private var _uvTransformData : Vector.<Number>;

		// todo: create something similar for diffuse: useOnlyProbesDiffuse - ignoring normal lights?
		// or: for both, provide mode: LightSourceMode.LIGHTS = 0x01, LightSourceMode.PROBES = 0x02, LightSourceMode.ALL = 0x03
		protected var _specularLightSources : uint = 0x01;
		protected var _diffuseLightSources : uint = 0x03;
		protected var _combinedLightSources : uint;

		protected var _colorTransformMethod : ColorTransformMethod;
		protected var _colorTransformMethodVO : MethodVO;
		protected var _normalMethod : BasicNormalMethod;
		protected var _normalMethodVO : MethodVO;
		protected var _ambientMethod : BasicAmbientMethod;
		protected var _ambientMethodVO : MethodVO;
		protected var _shadowMethod : ShadowMapMethodBase;
		protected var _shadowMethodVO : MethodVO;
		protected var _diffuseMethod : BasicDiffuseMethod;
		protected var _diffuseMethodVO : MethodVO;
		protected var _specularMethod : BasicSpecularMethod;
		protected var _specularMethodVO : MethodVO;
		protected var _methods : Vector.<MethodSet>;
		protected var _registerCache : ShaderRegisterCache;
		protected var _vertexCode : ShaderChunk;
		protected var _fragmentCode : Shader;
		protected var _projectionDependencies : uint;
		protected var _normalDependencies : uint;
		protected var _normalVDependencies : uint;
		protected var _viewDirDependencies : uint;
		protected var _uvDependencies : uint;
		protected var _vcDependencies : uint;
		protected var _secondaryUVDependencies : uint;
		protected var _globalPosDependencies : uint;
		protected var _reflectDependencies : uint;
		protected var _refractDependencies : uint;
		//private var _fastNrmMapDependencies : uint;

		// registers
		protected var _uvBufferIndex : int;
		protected var _secondaryUVBufferIndex : int;
		protected var _vcBufferIndex : int;
		protected var _normalBufferIndex : int;
		protected var _tangentBufferIndex : int;
		protected var _sceneMatrixIndex : int;
		protected var _sceneNormalMatrixIndex : int;
		protected var _lightDataIndex : int;
		protected var _cameraPositionIndex : int;
		protected var _uvTransformIndex : int;
		protected var _refractConstantIndex : int;

		protected var _projectionFragmentReg : ShaderRegisterElement;
		protected var _normalFragmentReg : ShaderRegisterElement;
		protected var _viewDirFragmentReg : ShaderRegisterElement;
		protected var _lightInputIndices : Vector.<uint>;
		protected var _lightProbeDiffuseIndices : Vector.<uint>;
		protected var _lightProbeSpecularIndices : Vector.<uint>;

		protected var _normalVarying : ShaderRegisterElement;
		protected var _tangentVarying : ShaderRegisterElement;
		protected var _bitangentVarying : ShaderRegisterElement;
		protected var _uvVaryingReg : ShaderRegisterElement;
		protected var _secondaryUVVaryingReg : ShaderRegisterElement;
		protected var _vcVaryingReg : ShaderRegisterElement;
		protected var _viewDirVaryingReg : ShaderRegisterElement;
		protected var _reflectVaryingReg : ShaderRegisterElement;
		protected var _refractVaryingReg : ShaderRegisterElement;
		
		protected var _normalVertexReg : ShaderRegisterElement;
		protected var _shadedTargetReg : ShaderRegisterElement;
		protected var _globalPositionVertexReg : ShaderRegisterElement;
		protected var _viewDirVertexReg : ShaderRegisterElement;
		protected var _globalPositionVaryingReg : ShaderRegisterElement;
		protected var _localPositionRegister : ShaderRegisterElement;
		protected var _positionMatrixRegs : Vector.<ShaderRegisterElement>;
		protected var _normalInput : ShaderRegisterElement;
		protected var _tangentInput : ShaderRegisterElement;
		protected var _animatedNormalReg : ShaderRegisterElement;
		protected var _animatedTangentReg : ShaderRegisterElement;
		
		protected var _commonsReg : ShaderRegisterElement;
		protected var _commonsDataIndex : int;
		protected var _extendedReg : ShaderRegisterElement;
		protected var _extendedDataIndex : int;

//		private var _commonsData : Vector.<Number> = Vector.<Number>([.5, 0, 0, 1]);
		protected var _vertexConstantIndex : uint;
		protected var _vertexConstantData : Vector.<Number> = new Vector.<Number>();
		protected var _fragmentConstantData : Vector.<Number> = new Vector.<Number>();

		arcane var _passes : Vector.<MaterialPassBase>;
		arcane var _passesDirty : Boolean;
		protected var _animateUVs : Boolean;

		protected var _numLights : int;
		protected var _lightDataLength : int;

		protected var _pointLightRegisters : Vector.<ShaderRegisterElement>;
		protected var _dirLightRegisters : Vector.<ShaderRegisterElement>;
		protected var _diffuseLightIndex : int;
		protected var _specularLightIndex : int;
		protected var _probeWeightsIndex : int;
		protected var _numProbeRegisters : uint;
		protected var _usingSpecularMethod : Boolean;
		protected var _usesGlobalPosFragment : Boolean = false;
		protected var _usesViewDirFragment : Boolean = false;
		protected var _usesNormalFragment : Boolean = false;
		protected var _usesHdr : Boolean = false;
		protected var _tangentDependencies : int;

		protected var _ambientLightR : Number;
		protected var _ambientLightG : Number;
		protected var _ambientLightB : Number;
		
		protected var _projectedTargetRegister : uint;



		/**
		 * Creates a new DefaultScreenPass objects.
		 */
		public function DefaultScreenPass(material : MaterialBase)
		{
			super();
			_material = material;

			init();
		}

		private function init() : void
		{
			_methods = new Vector.<MethodSet>();
			_normalMethod = new BasicNormalMethod();
			_ambientMethod = new BasicAmbientMethod();
			_diffuseMethod = new BasicDiffuseMethod();
			_specularMethod = new BasicSpecularMethod();
			_normalMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_diffuseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_specularMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_ambientMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_normalMethodVO = _normalMethod.createMethodVO();
			_ambientMethodVO = _ambientMethod.createMethodVO();
			_diffuseMethodVO = _diffuseMethod.createMethodVO();
			_specularMethodVO = _specularMethod.createMethodVO();
		}

		public function get animateUVs() : Boolean
		{
			return _animateUVs;
		}

		public function set animateUVs(value : Boolean) : void
		{
			_animateUVs = value;
			if ((value && !_animateUVs) || (!value && _animateUVs)) invalidateShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		override public function set mipmap(value : Boolean) : void
		{
			if (_mipmap == value) return;
			super.mipmap = value;
		}

		public function get specularLightSources() : uint
		{
			return _specularLightSources;
		}

		public function set specularLightSources(value : uint) : void
		{
			_specularLightSources = value;
		}

		public function get diffuseLightSources() : uint
		{
			return _diffuseLightSources;
		}

		public function set diffuseLightSources(value : uint) : void
		{
			_diffuseLightSources = value;
		}

		/**
		 * The ColorTransform object to transform the colour of the material with.
		 */
		public function get colorTransform() : ColorTransform
		{
			return _colorTransformMethod ? _colorTransformMethod.colorTransform : null;
		}

		public function set colorTransform(value : ColorTransform) : void
		{
			if (value) {
				colorTransformMethod ||= new ColorTransformMethod();
				_colorTransformMethod.colorTransform = value;
			}
			else if (!value) {
				if (_colorTransformMethod)
					colorTransformMethod = null;
				colorTransformMethod = _colorTransformMethod = null;
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose() : void
		{
			super.dispose();

			_normalMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_normalMethod.dispose();
			_diffuseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_diffuseMethod.dispose();
			if (_shadowMethod) {
				_shadowMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_shadowMethod.dispose();
			}
			_ambientMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_ambientMethod.dispose();
			if (_specularMethod) {
				_specularMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_specularMethod.dispose();
			}
			if (_colorTransformMethod) {
				_colorTransformMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_colorTransformMethod.dispose();
			}
			for (var i : int = 0; i < _methods.length; ++i) {
				_methods[i].method.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_methods[i].method.dispose();
			}
			
			
			_normalMethod 		  = null;
			_diffuseMethod        = null;
			_shadowMethod         = null;
			_ambientMethod        = null;
			_specularMethod       = null;
			_colorTransformMethod = null;
			_methods = null;
		}

		/**
		 * Adds a method to change the material after all lighting is performed.
		 * @param method The method to be added.
		 */
		public function addMethod(method : EffectMethodBase) : void
		{
			_methods.push(new MethodSet(method));
			method.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			invalidateShaderProgram();
		}

		public function hasMethod(method : EffectMethodBase) : Boolean
		{
			return getMethodSetForMethod(method) != null;
		}

		/**
		 * Inserts a method to change the material after all lighting is performed at the given index.
		 * @param method The method to be added.
		 * @param index The index of the method's occurrence
		 */
		public function addMethodAt(method : EffectMethodBase, index : int) : void
		{
			_methods.splice(index, 0, new MethodSet(method));
			method.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			invalidateShaderProgram();
		}

		public function getMethodAt(index : int) : EffectMethodBase
		{
			return EffectMethodBase(_methods[index].method);
		}

		public function get numMethods() : int
		{
			return _methods.length;
		}

		/**
		 * Removes a method from the pass.
		 * @param method The method to be removed.
		 */
		public function removeMethod(method : EffectMethodBase) : void
		{
			var methodSet : MethodSet = getMethodSetForMethod(method);
			if (methodSet != null) {
				var index : int = _methods.indexOf(methodSet);
				_methods.splice(index, 1);
				method.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				invalidateShaderProgram();
			}
		}

		/**
		 * The tangent space normal map to influence the direction of the surface for each texel.
		 */
		public function get normalMap() : Texture2DBase
		{
			return _normalMethod.normalMap;
		}

		public function set normalMap(value : Texture2DBase) : void
		{
			_normalMethod.normalMap = value;
		}

		/**
		 * @inheritDoc
		 */

		public function get normalMethod() : BasicNormalMethod
		{
			return _normalMethod;
		}

		public function set normalMethod(value : BasicNormalMethod) : void
		{
			_normalMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			value.copyFrom(_normalMethod);
			_normalMethod = value;
			_normalMethodVO = _normalMethod.createMethodVO();
			_normalMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			invalidateShaderProgram();
		}

		public function get ambientMethod() : BasicAmbientMethod
		{
			return _ambientMethod;
		}

		public function set ambientMethod(value : BasicAmbientMethod) : void
		{
			_ambientMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			value.copyFrom(_ambientMethod);
			_ambientMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_ambientMethod = value;
			_ambientMethodVO = _ambientMethod.createMethodVO();
			invalidateShaderProgram();
		}

		public function get shadowMethod() : ShadowMapMethodBase
		{
			return _shadowMethod;
		}

		public function set shadowMethod(value : ShadowMapMethodBase) : void
		{
			if (_shadowMethod) _shadowMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_shadowMethod = value;
			if (_shadowMethod) {
				_shadowMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_shadowMethodVO = _shadowMethod.createMethodVO();
			}
			else
				_shadowMethodVO = null;
			invalidateShaderProgram();
		}

		/**
		 * The method to perform diffuse shading.
		 */
		public function get diffuseMethod() : BasicDiffuseMethod
		{
			return _diffuseMethod;
		}

		public function set diffuseMethod(value : BasicDiffuseMethod) : void
		{
			_diffuseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			value.copyFrom(_diffuseMethod);
			_diffuseMethod = value;
			_diffuseMethodVO = _diffuseMethod.createMethodVO();
			_diffuseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			invalidateShaderProgram();
		}

		/**
		 * The method to perform specular shading.
		 */
		public function get specularMethod() : BasicSpecularMethod
		{
			return _specularMethod;
		}

		public function set specularMethod(value : BasicSpecularMethod) : void
		{
			if (_specularMethod) {
				_specularMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				if (value) value.copyFrom(_specularMethod);
			}

			_specularMethod = value;
			if (_specularMethod) {
				_specularMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_specularMethodVO = _specularMethod.createMethodVO();
			}
			else _specularMethodVO = null;

			invalidateShaderProgram();
		}



		/**
		 * @private
		 */
		arcane function get colorTransformMethod() : ColorTransformMethod
		{
			return _colorTransformMethod;
		}

		arcane function set colorTransformMethod(value : ColorTransformMethod) : void
		{
			if (_colorTransformMethod == value) return;
			if (_colorTransformMethod) _colorTransformMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			if (!_colorTransformMethod || !value) invalidateShaderProgram();

			_colorTransformMethod = value;
			if (_colorTransformMethod) {
				_colorTransformMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_colorTransformMethodVO = _colorTransformMethod.createMethodVO();
			}
			else _colorTransformMethodVO = null;
		}

		arcane override function set numPointLights(value : uint) : void
		{
			super.numPointLights = value;
			invalidateShaderProgram();
		}

		arcane override function set numDirectionalLights(value : uint) : void
		{
			super.numDirectionalLights = value;
			invalidateShaderProgram();
		}

		arcane override function set numLightProbes(value : uint) : void
		{
			super.numLightProbes = value;
			invalidateShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode(animatorCode : ShaderChunk) : Shader
		{
			
			
			var shader :  Shader = new Shader( Context3DProgramType.VERTEX );
			var normal : uint = _animationTargetRegisters.length > 1? _animationTargetRegisters[1] : 0;
			var projectionVertexCode : ShaderChunk = getProjectionCode(_animationTargetRegisters[0], _projectedTargetRegister, normal);
			shader.append(animatorCode);
			shader.append(projectionVertexCode);
			shader.append(_vertexCode);
			
			//_vertexCode = animatorCode + projectionVertexCode + _vertexCode;
			
			//TODO DEBUG
			if( _material && _logmap.indexOf( _material.name ) > -1 ) {
				trace( "############################################" );
				trace( "###         "+ _material.name  );
				trace( "############################################" );
				trace( "\nVERTEX    " );
				trace( Dump.dumpShader( shader ) );
				trace( "\FRAGMENT " );
				trace( Dump.dumpShader( _fragmentCode ) );
			}
			return shader;
		}

		protected function getProjectionCode(positionRegister : uint, projectionRegister : uint, normalRegister : uint) : ShaderChunk
		{
			var code : ShaderChunk = new ShaderChunk();
			var pos : uint = positionRegister;

			// if we need projection somewhere
			if (projectionRegister > 0 ) {
				
				code.m44( projectionRegister, pos, c0 );
				code.mov( t7, projectionRegister );
				code.mul( op, t7, c4 );
				
//				code += "m44 "+projectionRegister+", " + pos + ", vc0		\n" +
//						"mov vt7, " + projectionRegister + "\n" +
//						"mul op, vt7, vc4\n";
			}
			else {
				code.m44( t7, pos, c0 );
				code.mul( op, t7, c4 );
//				code += "m44 vt7, "+pos+", vc0		\n" +
//						"mul op, vt7, vc4\n";	// 4x4 matrix transform from stream 0 to output clipspace
			}
			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : Shader
		{
			return _fragmentCode;
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, textureRatioX : Number, textureRatioY : Number) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			var len : uint = _methods.length;

			super.activate(stage3DProxy, camera, textureRatioX, textureRatioY);

			if (_normalDependencies > 0 && _normalMethod.hasOutput) _normalMethod.activate(_normalMethodVO, stage3DProxy);
			_ambientMethod.activate(_ambientMethodVO, stage3DProxy);
			if (_shadowMethod) _shadowMethod.activate(_shadowMethodVO, stage3DProxy);
			_diffuseMethod.activate(_diffuseMethodVO, stage3DProxy);
			if (_usingSpecularMethod) _specularMethod.activate(_specularMethodVO, stage3DProxy);
			if (_colorTransformMethod) _colorTransformMethod.activate(_colorTransformMethodVO, stage3DProxy);

			for (var i : int = 0; i < len; ++i) {
				var set : MethodSet = _methods[i];
				set.method.activate(set.data, stage3DProxy);
			}

			if (_cameraPositionIndex >= 0) {
				var pos : Vector3D = camera.scenePosition;
				_vertexConstantData[_cameraPositionIndex] = pos.x;
				_vertexConstantData[_cameraPositionIndex + 1] = pos.y;
				_vertexConstantData[_cameraPositionIndex + 2] = pos.z;
			}
		}

		/**
		 * @inheritDoc
		 */
		arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
		{
			super.deactivate(stage3DProxy);
			var len : uint = _methods.length;

			if (_normalDependencies > 0 && _normalMethod.hasOutput) _normalMethod.deactivate(_normalMethodVO, stage3DProxy);
			_ambientMethod.deactivate(_ambientMethodVO, stage3DProxy);
			if (_shadowMethod) _shadowMethod.deactivate(_shadowMethodVO, stage3DProxy);
			_diffuseMethod.deactivate(_diffuseMethodVO, stage3DProxy);
			if (_usingSpecularMethod) _specularMethod.deactivate(_specularMethodVO, stage3DProxy);
			if (_colorTransformMethod) _colorTransformMethod.deactivate(_colorTransformMethodVO, stage3DProxy);

			var set : MethodSet;
			for (var i : uint = 0; i < len; ++i) {
				set = _methods[i];
				set.method.deactivate(set.data, stage3DProxy);
			}
		}

		/**
		 * @inheritDoc
		 */
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D, lightPicker : LightPickerBase) : void
		{
			var i : uint;
			var context : Context3D = stage3DProxy._context3D;
			if (_uvBufferIndex >= 0) stage3DProxy.setSimpleVertexBuffer(_uvBufferIndex, renderable.getUVBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_2, renderable.UVBufferOffset);
			if (_secondaryUVBufferIndex >= 0) stage3DProxy.setSimpleVertexBuffer(_secondaryUVBufferIndex, renderable.getSecondaryUVBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_2, renderable.secondaryUVBufferOffset);
			if (_vcBufferIndex >= 0) stage3DProxy.setSimpleVertexBuffer(_vcBufferIndex, renderable.getVertexColorBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, renderable.normalBufferOffset);
			if (_normalBufferIndex >= 0) stage3DProxy.setSimpleVertexBuffer(_normalBufferIndex, renderable.getVertexNormalBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, renderable.normalBufferOffset);
			if (_tangentBufferIndex >= 0) stage3DProxy.setSimpleVertexBuffer(_tangentBufferIndex, renderable.getVertexTangentBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3, renderable.tangentBufferOffset);

			var uvTransform : Matrix;
			if (_animateUVs) {
				uvTransform = renderable.uvTransform;
				if (uvTransform) {
					_vertexConstantData[_uvTransformIndex] = uvTransform.a;
					_vertexConstantData[_uvTransformIndex+1] = uvTransform.b;
					_vertexConstantData[_uvTransformIndex+3] = uvTransform.tx;
					_vertexConstantData[_uvTransformIndex+4] = uvTransform.c;
					_vertexConstantData[_uvTransformIndex+5] = uvTransform.d;
					_vertexConstantData[_uvTransformIndex+7] = uvTransform.ty;
				}
				else {
					trace("Warning: animateUVs is set to true with an IRenderable without a uvTransform. Identity matrix assumed.");
					_vertexConstantData[_uvTransformIndex] = 1;
					_vertexConstantData[_uvTransformIndex+1] = 0;
					_vertexConstantData[_uvTransformIndex+3] = 0;
					_vertexConstantData[_uvTransformIndex+4] = 0;
					_vertexConstantData[_uvTransformIndex+5] = 1;
					_vertexConstantData[_uvTransformIndex+7] = 0;
				}
			}

			if (_numLights > 0 && (_combinedLightSources & LightSources.LIGHTS))
				updateLights(lightPicker.directionalLights, lightPicker.pointLights, stage3DProxy);

			if (_numLightProbes > 0 && (_combinedLightSources & LightSources.PROBES))
				updateProbes(lightPicker.lightProbes, lightPicker.lightProbeWeights, stage3DProxy);

			if (_sceneMatrixIndex >= 0)
				renderable.sceneTransform.copyRawDataTo(_vertexConstantData, _sceneMatrixIndex, true);

			if (_sceneNormalMatrixIndex >= 0)
				renderable.inverseSceneTransform.copyRawDataTo(_vertexConstantData, _sceneNormalMatrixIndex, false);

			if (_normalDependencies > 0 && _normalMethod.hasOutput)
				_normalMethod.setRenderState(_normalMethodVO, renderable, stage3DProxy, camera);

			_ambientMethod.setRenderState(_ambientMethodVO, renderable, stage3DProxy, camera);
			_ambientMethod._lightAmbientR = _ambientLightR;
			_ambientMethod._lightAmbientG = _ambientLightG;
			_ambientMethod._lightAmbientB = _ambientLightB;

			if (_shadowMethod) _shadowMethod.setRenderState(_shadowMethodVO, renderable, stage3DProxy, camera);
			_diffuseMethod.setRenderState(_diffuseMethodVO, renderable, stage3DProxy, camera);
			if (_usingSpecularMethod) _specularMethod.setRenderState(_specularMethodVO, renderable, stage3DProxy, camera);
			if (_colorTransformMethod) _colorTransformMethod.setRenderState(_colorTransformMethodVO, renderable, stage3DProxy, camera);

			var len : uint = _methods.length;
			for (i = 0; i < len; ++i) {
				var set : MethodSet = _methods[i];
				set.method.setRenderState(set.data, renderable, stage3DProxy, camera);
			}

			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _vertexConstantIndex, _vertexConstantData, _numUsedVertexConstants-_vertexConstantIndex);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentConstantData, _numUsedFragmentConstants);

			super.render(renderable, stage3DProxy, camera, lightPicker);
		}


		/**
		 * Marks the shader program as invalid, so it will be recompiled before the next render.
		 */
		arcane override function invalidateShaderProgram(updateMaterial : Boolean = true) : void
		{
			super.invalidateShaderProgram(updateMaterial);
			_passesDirty = true;

			_passes = new Vector.<MaterialPassBase>();
			if (_normalMethod.hasOutput) addPasses(_normalMethod.passes);
			addPasses(_ambientMethod.passes);
			if (_shadowMethod) addPasses(_shadowMethod.passes);
			addPasses(_diffuseMethod.passes);
			if (_specularMethod) addPasses(_specularMethod.passes);
			if (_colorTransformMethod) addPasses(_colorTransformMethod.passes);

			for (var i : uint = 0; i < _methods.length; ++i) {
				addPasses(_methods[i].method.passes);
			}
		}

		/**
		 * @inheritDoc
		 */
		override arcane function updateProgram(stage3DProxy : Stage3DProxy) : void
		{
			reset();

			super.updateProgram(stage3DProxy);
		}

		/**
		 * Resets the compilation state.
		 */
		protected function reset() : void
		{
			_numLights = _numPointLights + _numDirectionalLights;
			_numProbeRegisters = Math.ceil(_numLightProbes/4);

			if (_specularMethod)
				_combinedLightSources = _specularLightSources | _diffuseLightSources;
			else
				_combinedLightSources = _diffuseLightSources;

			_usingSpecularMethod = 	_specularMethod && (
									(_numLights > 0 && (_specularLightSources & LightSources.LIGHTS)) ||
									(_numLightProbes > 0 && (_specularLightSources & LightSources.PROBES)));

			_uvTransformIndex = -1;
			_cameraPositionIndex = -1;
			_refractConstantIndex = -1;
			_commonsDataIndex = -1;
			_extendedDataIndex = -1;
			_uvBufferIndex = -1;
			_vcBufferIndex = -1;
			_secondaryUVBufferIndex = -1;
			_normalBufferIndex = -1;
			_tangentBufferIndex = -1;
			_lightDataIndex = -1;
			_sceneMatrixIndex = -1;
			_sceneNormalMatrixIndex = -1;
			_probeWeightsIndex = -1;

			_pointLightRegisters = new Vector.<ShaderRegisterElement>(_numPointLights*3, true);
			_dirLightRegisters = new Vector.<ShaderRegisterElement>(_numDirectionalLights*3, true);
			_lightDataLength = _numLights*3;

			_registerCache = new ShaderRegisterCache();
			_vertexConstantIndex = _registerCache.vertexConstantOffset = 5;
			_registerCache.vertexAttributesOffset = 1;
			_registerCache.reset();

			_lightInputIndices = new Vector.<uint>(_numLights, true);

			_commonsReg = null;
			_numUsedVertexConstants = 0;
			_numUsedStreams = 1;

			_animatableAttributes = new <uint>[ a0 ];
			_animationTargetRegisters = new <uint>[ t0 ];
			_vertexCode = new ShaderChunk();
			_fragmentCode = new Shader( Context3DProgramType.FRAGMENT );
			_projectedTargetRegister = 0;

			_localPositionRegister = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_localPositionRegister, 1);

			compile();
			
			if( _material && _logmap.indexOf( _material.name ) > -1 ) {
				trace( "############################################" );
				trace( "###         "+ _material.name  );
				trace( "############################################" );
				trace( "\n _numUsedTextures    " );
				trace( _numUsedTextures );
			}

			_numUsedVertexConstants = _registerCache.numUsedVertexConstants;
			_numUsedFragmentConstants = _registerCache.numUsedFragmentConstants;
			_numUsedStreams = _registerCache.numUsedStreams;
			_numUsedTextures = _registerCache.numUsedTextures;
			_vertexConstantData.length = (_numUsedVertexConstants-_vertexConstantIndex)*4;
			_fragmentConstantData.length = _numUsedFragmentConstants*4;

			initCommonsData();
			if (_uvTransformIndex >= 0)
				initUVTransformData();
			if (_cameraPositionIndex >= 0)
				_vertexConstantData[_cameraPositionIndex + 3] = 1;
			if (_refractConstantIndex >= 0)
				_vertexConstantData[_refractConstantIndex] = 0.9;
			if( _usesHdr ) 
				initExtendedData();
			
//			if (_reflectionConstIndex >= 0) {
//				_vertexConstantData[_reflectionConstIndex] = .0546233;
//				_vertexConstantData[_reflectionConstIndex+1] = 1.0-.0546233;
//				_vertexConstantData[_reflectionConstIndex+2] = .7;
//				_vertexConstantData[_reflectionConstIndex+3] = 1.0;
//			}

			updateMethodConstants();
			cleanUp();
		}

		protected function updateMethodConstants() : void
		{
			if (_normalMethod) _normalMethod.initConstants(_normalMethodVO);
			if (_diffuseMethod) _diffuseMethod.initConstants(_diffuseMethodVO);
			if (_ambientMethod) _ambientMethod.initConstants(_ambientMethodVO);
			if (_specularMethod) _specularMethod.initConstants(_specularMethodVO);
			if (_shadowMethod) _shadowMethod.initConstants(_shadowMethodVO);
			if (_colorTransformMethod) _colorTransformMethod.initConstants(_colorTransformMethodVO);

			var len : uint = _methods.length;
			for (var i : uint = 0; i < len; ++i) {
				_methods[i].method.initConstants(_methods[i].data);
			}
		}

		protected function initUVTransformData() : void
		{
			_vertexConstantData[_uvTransformIndex] = 1;
			_vertexConstantData[_uvTransformIndex+1] = 0;
			_vertexConstantData[_uvTransformIndex+2] = 0;
			_vertexConstantData[_uvTransformIndex+3] = 0;
			_vertexConstantData[_uvTransformIndex+4] = 0;
			_vertexConstantData[_uvTransformIndex+5] = 1;
			_vertexConstantData[_uvTransformIndex+6] = 0;
			_vertexConstantData[_uvTransformIndex+7] = 0;
		}

		protected function initCommonsData() : void
		{
			_fragmentConstantData[_commonsDataIndex] = .5;
			_fragmentConstantData[_commonsDataIndex + 1] = 0;
			_fragmentConstantData[_commonsDataIndex + 2] = 1/255;
			_fragmentConstantData[_commonsDataIndex + 3] = 1;
			//_fragmentConstantData[_commonsDataIndex + 4] = 1;
		}

		protected function initExtendedData() : void
		{
//			_fragmentConstantData[_extendedDataIndex] = 1.309;
//			_fragmentConstantData[_extendedDataIndex + 1] = 1.0-1.309; 
			_fragmentConstantData[_extendedDataIndex] = 0.9; // refraction indice
			_fragmentConstantData[_extendedDataIndex + 1] = 1.0-0.9; 
			
			_fragmentConstantData[_extendedDataIndex + 2] = .0546233; // fresnel const
			_fragmentConstantData[_extendedDataIndex + 3] = 1.0-.0546233;
		}

		protected function cleanUp() : void
		{
			nullifyCompilationData();
			cleanUpMethods();
		}

		protected function nullifyCompilationData() : void
		{
			_pointLightRegisters = null;
			_dirLightRegisters = null;

			_projectionFragmentReg = null;
			_viewDirFragmentReg = null;

			_normalVarying = null;
			_tangentVarying = null;
			_bitangentVarying = null;
			_uvVaryingReg = null;
			_secondaryUVVaryingReg = null;
			_viewDirVaryingReg = null;
			
			_reflectVaryingReg = null;
			_viewDirVertexReg = null;

			_shadedTargetReg = null;
			_globalPositionVertexReg = null;
			_globalPositionVaryingReg = null;
			_localPositionRegister = null;
			_positionMatrixRegs = null;
			_normalInput = null;
			_tangentInput = null;
			_animatedNormalReg = null;
			_animatedTangentReg = null;
			_commonsReg = null;
			
			_usesGlobalPosFragment = false;
			_usesViewDirFragment = false;
			_usesNormalFragment = false;
			_usesHdr = false;

			_registerCache.dispose();
			_registerCache = null;
		}

		protected function cleanUpMethods() : void
		{
			if (_normalMethod) _normalMethod.cleanCompilationData();
			if (_diffuseMethod) _diffuseMethod.cleanCompilationData();
			if (_ambientMethod) _ambientMethod.cleanCompilationData();
			if (_specularMethod) _specularMethod.cleanCompilationData();
			if (_shadowMethod) _shadowMethod.cleanCompilationData();
			if (_colorTransformMethod) _colorTransformMethod.cleanCompilationData();

			var len : uint = _methods.length;
			for (var i : uint = 0; i < len; ++i) {
				_methods[i].method.cleanCompilationData();
			}
		}

		/**
		 * Compiles the actual shader code.
		 */
		protected function compile() : void
		{
			
			createCommons();
			calculateDependencies();
			
			if( _usesHdr ) 
				createHdr();
			if (_projectionDependencies > 0) compileProjCode();
			if (_uvDependencies > 0) compileUVCode();
			if (_secondaryUVDependencies > 0) compileSecondaryUVCode();
			if (_vcDependencies > 0) compileVCCode();
			if (_globalPosDependencies > 0) compileGlobalPositionCode();

			updateMethodRegisters(_normalMethod);
			if (_normalDependencies > 0 || _normalVDependencies > 0 ) {
				// needs to be created before view
				_animatedNormalReg = _registerCache.getFreeVertexVectorTemp();
				_registerCache.addVertexTempUsages(_animatedNormalReg, 1);
				compileNormalCode();
			}
			
			if (_viewDirDependencies > 0) compileViewDirCode();
			if (_reflectDependencies > 0) compileReflectCode();
			if (_refractDependencies > 0) compileRefractCode();


			updateMethodRegisters(_diffuseMethod);
			if (_shadowMethod) updateMethodRegisters(_shadowMethod);
			updateMethodRegisters(_ambientMethod);
			if (_specularMethod) updateMethodRegisters(_specularMethod);
			if (_colorTransformMethod) updateMethodRegisters(_colorTransformMethod);

			for (var i : uint = 0; i < _methods.length; ++i)
				updateMethodRegisters(_methods[i].method);

			_shadedTargetReg = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(_shadedTargetReg, 1);

			
		
			compileLightingCode();
			compileMethods();
			_fragmentCode.mov( _registerCache.fragmentOutputRegister.value(), _shadedTargetReg.value() )
//			_fragmentCode += "mov " + _registerCache.fragmentOutputRegister + ", " + _shadedTargetReg + "\n";

			_registerCache.removeFragmentTempUsage(_shadedTargetReg);
		}


		protected function compileProjCode() : void
		{
			_projectionFragmentReg = _registerCache.getFreeVarying();
			_projectedTargetRegister = _registerCache.getFreeVertexVectorTemp().value();

			//_vertexCode += "mov " + _projectionFragmentReg + ", " + _projectedTargetRegister + "\n";
			_vertexCode.mul( _projectionFragmentReg.value(), t7, c4 );
			//_vertexCode += "mul "+_projectionFragmentReg.value()+", vt7, vc4 \n";
		}

		protected function updateMethodRegisters(method : ShadingMethodBase) : void
		{
			method.globalPosReg = _globalPositionVaryingReg;
			method.normalFragmentReg = _normalFragmentReg;
			method.normalVaryingReg = _normalVarying;
			method.reflectVaryingReg = _reflectVaryingReg;
			method.refractVaryingReg = _refractVaryingReg;
			method.projectionReg = _projectionFragmentReg;
			method.UVFragmentReg = _uvVaryingReg;
			method.VCFragmentReg = _vcVaryingReg;
			method.tangentVaryingReg = _tangentVarying;
			method.bitanVaryingReg = _bitangentVarying;
			method.secondaryUVFragmentReg = _secondaryUVVaryingReg;
			method.viewDirFragmentReg = _viewDirFragmentReg;
			method.viewDirVaryingReg = _viewDirVaryingReg;
			method.commonFragReg = _commonsReg;
			method.extendedReg = _extendedReg;
		}

		/**
		 * Adds passes to the list.
		 */
		protected function addPasses(passes : Vector.<MaterialPassBase>) : void
		{
			if (!passes) return;

			var len : uint = passes.length;

			for (var i : uint = 0; i < len; ++i) {
				passes[i].material = material;
				_passes.push(passes[i]);
			}
		}

		/**
		 * Calculates register dependencies for commonly used data.
		 */
		protected function calculateDependencies() : void
		{
			var len : uint;

			_normalDependencies = 0;
			_normalVDependencies = 0;
			_viewDirDependencies = 0;
			_reflectDependencies = 0;
			_refractDependencies = 0;
			//_fastNrmMapDependencies = 0;
			_uvDependencies = 0;
			_secondaryUVDependencies = 0;
			_vcDependencies = 0;
			_globalPosDependencies = 0;

			setupAndCountMethodDependencies(_diffuseMethod, _diffuseMethodVO);
			if (_shadowMethod) setupAndCountMethodDependencies(_shadowMethod, _shadowMethodVO);
			setupAndCountMethodDependencies(_ambientMethod, _ambientMethodVO);
			if (_usingSpecularMethod) setupAndCountMethodDependencies(_specularMethod, _specularMethodVO);
			if (_colorTransformMethod) setupAndCountMethodDependencies(_colorTransformMethod, _colorTransformMethodVO);

			len = _methods.length;
			for (var i : uint = 0; i < len; ++i)
				setupAndCountMethodDependencies(_methods[i].method, _methods[i].data);
			
			_usesNormalFragment = _normalDependencies > 0;
			_usesViewDirFragment = _viewDirDependencies > 0;
			
			if (_reflectDependencies > 0) {
				++_normalVDependencies;
				++_viewDirDependencies;
			}
			if (_refractDependencies > 0) {
				++_normalVDependencies;
				++_viewDirDependencies;
			}
			if (_normalDependencies > 0 && _normalMethod.hasOutput) setupAndCountMethodDependencies(_normalMethod, _normalMethodVO);
			if (_viewDirDependencies > 0) ++_globalPosDependencies;

			// todo: add spotlight check
			if (_numPointLights > 0 && (_combinedLightSources & LightSources.LIGHTS)) {
				++_globalPosDependencies;
				_usesGlobalPosFragment = true;
			}
		}

		protected function setupAndCountMethodDependencies(method : ShadingMethodBase, methodVO : MethodVO) : void
		{
			setupMethod(method, methodVO);
			countDependencies(methodVO);
		}

		protected function countDependencies(methodVO : MethodVO) : void
		{
			if (methodVO.needsProjection) ++_projectionDependencies;
			if (methodVO.needsGlobalPos) {
				++_globalPosDependencies;
				_usesGlobalPosFragment = true;
			}
			if (methodVO.needsNormals) ++_normalDependencies;
			if (methodVO.needsNormalVarying) ++_normalVDependencies;
			if (methodVO.needsTangents) ++_tangentDependencies;
			if (methodVO.needsView) ++_viewDirDependencies;
			if (methodVO.needsUV) ++_uvDependencies;
			if (methodVO.needsSecondaryUV) ++_secondaryUVDependencies;
			if (methodVO.needsColors) ++_vcDependencies;
			if (methodVO.needsReflect ) ++_reflectDependencies;
			if (methodVO.needsRefract ) ++_refractDependencies;
//			if (methodVO.needsFastNrm ) ++_fastNrmMapDependencies;
			
			_usesHdr ||= methodVO.needsExtendedData || methodVO.needsRefract;
		}

		protected function setupMethod(method : ShadingMethodBase, methodVO : MethodVO) : void
		{
			method.reset();
			methodVO.reset();
			methodVO.vertexData = _vertexConstantData;
			methodVO.fragmentData = _fragmentConstantData;
			methodVO.vertexConstantsOffset = _vertexConstantIndex;
			methodVO.useSmoothTextures = _smooth;
			methodVO.repeatTextures = _repeat;
			methodVO.useMipmapping = _mipmap;
			methodVO.numLights = _numLights + _numLightProbes;
			method.initVO(methodVO);
		}

		protected function compileGlobalPositionCode() : void
		{
			_globalPositionVertexReg = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_globalPositionVertexReg, _globalPosDependencies);

			_positionMatrixRegs = new Vector.<ShaderRegisterElement>();
			_positionMatrixRegs[0] = _registerCache.getFreeVertexConstant();
			_positionMatrixRegs[1] = _registerCache.getFreeVertexConstant();
			_positionMatrixRegs[2] = _registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_sceneMatrixIndex = (_positionMatrixRegs[0].index - _vertexConstantIndex)*4;

//			_vertexCode += 	"m44 " + _globalPositionVertexReg + ".xyz, " + _localPositionRegister.toString() + ", " + _positionMatrixRegs[0].toString() + "\n" +
//							"mov " + _globalPositionVertexReg + ".w, " + _localPositionRegister + ".w     \n";
			_vertexCode.m44( _globalPositionVertexReg.value()^xyz, _localPositionRegister.value(), _positionMatrixRegs[0].value() );		
			_vertexCode.mov( _globalPositionVertexReg.value()^w, _localPositionRegister.value()^w );		
//			_registerCache.removeVertexTempUsage(_localPositionRegister);

			// todo: add spotlight check as well
			if (_usesGlobalPosFragment) {
				_globalPositionVaryingReg = _registerCache.getFreeVarying();
//				_vertexCode += "mov " + _globalPositionVaryingReg + ", " + _globalPositionVertexReg + "\n";
				_vertexCode.mov( _globalPositionVaryingReg.value(), _globalPositionVertexReg.value() );
//				_registerCache.removeVertexTempUsage(_globalPositionVertexReg);
			}
		}
		
		
		protected function compileUVCode() : void
		{
			var uvAttributeReg : ShaderRegisterElement = _registerCache.getFreeVertexAttribute();

			_uvVaryingReg = _registerCache.getFreeVarying();
			_uvBufferIndex = uvAttributeReg.index;

			if (_animateUVs) {
				// a, b, 0, tx
				// c, d, 0, ty
				var uvTransform1 : ShaderRegisterElement = _registerCache.getFreeVertexConstant();
				var uvTransform2 : ShaderRegisterElement = _registerCache.getFreeVertexConstant();
				_uvTransformIndex = (uvTransform1.index - _vertexConstantIndex)*4;

//				_vertexCode += 	"dp4 " + _uvVaryingReg + ".x, " + uvAttributeReg + ", " + uvTransform1 + "\n" +
//								"dp4 " + _uvVaryingReg + ".y, " + uvAttributeReg + ", " + uvTransform2 + "\n" +
//								"mov " + _uvVaryingReg + ".zw, " + uvAttributeReg + ".zw \n";
								
				_vertexCode.dp4( _uvVaryingReg.value() ^ x , uvAttributeReg.value(), uvTransform1.value() );
				_vertexCode.dp4( _uvVaryingReg.value() ^ y , uvAttributeReg.value(), uvTransform2.value() );
				_vertexCode.mov( _uvVaryingReg.value() ^ zw , uvAttributeReg.value() ^ zw );
			}
			else {
//				_vertexCode += "mov " + _uvVaryingReg + ", " + uvAttributeReg + "\n";
				_vertexCode.mov( _uvVaryingReg.value() , uvAttributeReg.value() );
			}
		}

		protected function compileVCCode() : void
		{
			var vcAttributeReg : ShaderRegisterElement = _registerCache.getFreeVertexAttribute();

			_vcVaryingReg = _registerCache.getFreeVarying();
			_vcBufferIndex = vcAttributeReg.index;

//			_vertexCode += "mov " + _vcVaryingReg + ", " + vcAttributeReg + "\n";
			_vertexCode.mov( _vcVaryingReg.value() , vcAttributeReg.value() );
			
		}

		protected function compileSecondaryUVCode() : void
		{
			var uvAttributeReg : ShaderRegisterElement = _registerCache.getFreeVertexAttribute();

			_secondaryUVVaryingReg = _registerCache.getFreeVarying();
			_secondaryUVBufferIndex = uvAttributeReg.index;

//			_vertexCode += "mov " + _secondaryUVVaryingReg + ", " + uvAttributeReg + "\n";
			_vertexCode.mov( _secondaryUVVaryingReg.value() , uvAttributeReg.value() );
		}

		protected function compileNormalCode() : void
		{
			var normalMatrix : Vector.<ShaderRegisterElement> = new Vector.<ShaderRegisterElement>(3, true);
			
			var onlyVarying : Boolean = _normalDependencies == 0;
			if( _material && _logmap.indexOf( _material.name ) > -1 )
				trace( "away3d.materials.passes.DefaultScreenPass - compileNormalCode -- ", _normalDependencies);
			
			_normalFragmentReg = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(_normalFragmentReg, _normalDependencies);
			
			if (_normalMethod.hasOutput && !_normalMethod.tangentSpace) {
				var chunk : ShaderChunk;

				chunk = _normalMethod.getVertexCode(_normalMethodVO, _registerCache);
				if( chunk ) _vertexCode.append( chunk );

				chunk = _normalMethod.getFragmentCode(_normalMethodVO, _registerCache, _normalFragmentReg);
				if( chunk ) _fragmentCode.append( chunk );
				
				return;
			}

			_normalInput = _registerCache.getFreeVertexAttribute();
			_normalBufferIndex = _normalInput.index;

			_normalVarying = _registerCache.getFreeVarying();
			var nrmdep : int = (( _reflectDependencies > 0 ) ? 1 : 0) +( ( _refractDependencies > 0 ) ? 1 : 0);
			if( nrmdep > 0 ) {
				_normalVertexReg = _registerCache.getFreeVertexVectorTemp();
				_registerCache.addVertexTempUsages( _normalVertexReg , nrmdep );
			} 
			else
				_normalVertexReg = _normalVarying;
				
			_animatableAttributes.push(_normalInput.value() );
			_animationTargetRegisters.push(_animatedNormalReg.value() );

			normalMatrix[0] = _registerCache.getFreeVertexConstant();
			normalMatrix[1] = _registerCache.getFreeVertexConstant();
			normalMatrix[2] = _registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_sceneNormalMatrixIndex = (normalMatrix[0].index-_vertexConstantIndex)*4;

			if (_normalMethod.hasOutput) {
				// tangent stream required
				compileTangentVertexCode(normalMatrix);
				compileTangentNormalMapFragmentCode();
			}
			else {
//				_vertexCode += 	"m33 " + _normalVertexReg + ".xyz, " + _animatedNormalReg + ".xyz, " + normalMatrix[0] + "\n" +
//								"mov " + _normalVertexReg + ".w, " + _animatedNormalReg + ".w	\n";
				
				_vertexCode.m33( _normalVertexReg.value() ^ xyz, _animatedNormalReg.value() ^ xyz, normalMatrix[0].value() );
				_vertexCode.mov( _normalVertexReg.value() ^ w , _animatedNormalReg.value() ^ w );
				
				if( _reflectDependencies > 0 ) {
					//_vertexCode +=  "nrm " + _normalVertexReg + ".xyz, " + _normalVertexReg + ".xyz	\n";
//					_vertexCode += 	"mov " + _normalVarying + ", " + _normalVertexReg + "	\n";
					_vertexCode.mov( _normalVarying.value()  , _normalVertexReg.value() );
				}
					
				if( _usesNormalFragment && !onlyVarying ) {
//					_fragmentCode += "nrm " + _normalFragmentReg + ".xyz, " + _normalVarying + ".xyz	\n" +
//									"mov " + _normalFragmentReg + ".w, " + _normalVarying + ".w		\n";

					_fragmentCode.nrm( _normalFragmentReg.value() ^ xyz,  	_normalVarying.value() ^ xyz  );
					_fragmentCode.mov( _normalFragmentReg.value() ^ w , 	_normalVarying.value() ^ w );
				}


				if (_tangentDependencies > 0) {
					_tangentInput = _registerCache.getFreeVertexAttribute();
					_tangentBufferIndex = _tangentInput.index;
					_tangentVarying = _registerCache.getFreeVarying();
//					_vertexCode += "mov " + _tangentVarying + ", " + _tangentInput + "\n";
					_vertexCode.mov( _tangentVarying.value()  , _tangentInput.value() );
				}
				
				//if (_fastNrmMapDependencies > 0) compileFastNormalMap();
			}

			_registerCache.removeVertexTempUsage(_animatedNormalReg);
		}

		protected function compileTangentVertexCode(matrix : Vector.<ShaderRegisterElement>) : void
		{
			var normalTemp : ShaderRegisterElement;
			var tanTemp : ShaderRegisterElement;
			var bitanTemp1 : ShaderRegisterElement;
			var bitanTemp2 : ShaderRegisterElement;

			_tangentVarying = _registerCache.getFreeVarying();
			_bitangentVarying = _registerCache.getFreeVarying();

			_tangentInput = _registerCache.getFreeVertexAttribute();
			_tangentBufferIndex = _tangentInput.index;

			_animatedTangentReg = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_animatedTangentReg, 1);
			_animatableAttributes.push(_tangentInput.value() );
			_animationTargetRegisters.push(_animatedTangentReg.value());

			normalTemp = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(normalTemp, 1);

//			_vertexCode += 	"m33 " + normalTemp + ".xyz, " + _animatedNormalReg + ".xyz, " + matrix[0].toString() + "\n" +
//							"nrm " + normalTemp + ".xyz, " + normalTemp + ".xyz	\n";
			_vertexCode.m33( normalTemp.value() ^ xyz, _animatedNormalReg.value() ^ xyz, matrix[0].value() );
			_vertexCode.nrm( normalTemp.value() ^ xyz, normalTemp.value() ^ xyz );
			
			
			tanTemp = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(tanTemp, 1);

//			_vertexCode += 	"m33 " + tanTemp + ".xyz, " + _animatedTangentReg + ".xyz, " + matrix[0].toString() + "\n" +
//							"nrm " + tanTemp + ".xyz, " + tanTemp + ".xyz	\n";
			_vertexCode.m33( tanTemp.value() ^ xyz, _animatedTangentReg.value() ^ xyz, matrix[0].value() );
			_vertexCode.nrm( tanTemp.value() ^ xyz, tanTemp.value() ^ xyz );

			bitanTemp1 = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(bitanTemp1, 1);
			bitanTemp2 = _registerCache.getFreeVertexVectorTemp();

			_vertexCode.mul( bitanTemp1.value()  ^ xyz, 		normalTemp.value()  ^ yzx, tanTemp.value()  ^ zxy);
			_vertexCode.mul( bitanTemp2.value()  ^ xyz, 		normalTemp.value()  ^ zxy, tanTemp.value()  ^ yzx);
			_vertexCode.sub( bitanTemp2.value()  ^ xyz, 		bitanTemp1.value()  ^ xyz, bitanTemp2.value()  ^ xyz	); 
			_vertexCode.mov( _tangentVarying.value()  ^ x,	tanTemp.value()  ^ x	); 
			_vertexCode.mov( _tangentVarying.value()  ^ y,	bitanTemp2.value()  ^ x	); 
			_vertexCode.mov( _tangentVarying.value()  ^ z,	normalTemp.value()  ^ x	); 
			_vertexCode.mov( _tangentVarying.value()  ^ w,	_normalInput.value()  ^ w); 
			_vertexCode.mov( _bitangentVarying.value()  ^ x, tanTemp.value()  ^ y	); 
			_vertexCode.mov( _bitangentVarying.value()  ^ y, bitanTemp2.value()  ^ y	); 
			_vertexCode.mov( _bitangentVarying.value()  ^ z, normalTemp.value()  ^ y	); 
			_vertexCode.mov( _bitangentVarying.value()  ^ w, _normalInput.value()  ^ w); 
			_vertexCode.mov( _normalVarying.value()  ^ x, 	tanTemp.value()  ^ z	); 
			_vertexCode.mov( _normalVarying.value()  ^ y, 	bitanTemp2.value()  ^ z	); 
			_vertexCode.mov( _normalVarying.value()  ^ z, 	normalTemp.value()  ^ z	); 
			_vertexCode.mov( _normalVarying.value()  ^ w, 	_normalInput.value()  ^ w); 

			_registerCache.removeVertexTempUsage(normalTemp);
			_registerCache.removeVertexTempUsage(tanTemp);
			_registerCache.removeVertexTempUsage(bitanTemp1);
			_registerCache.removeVertexTempUsage(_animatedTangentReg);
		}

		protected function compileTangentNormalMapFragmentCode() : void
		{
			var t : ShaderRegisterElement;
			var b : ShaderRegisterElement;
			var n : ShaderRegisterElement;

			t = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(t, 1);
			b = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(b, 1);
			n = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(n, 1);

			_fragmentCode.nrm(t.value() ^ xyz, 	 _tangentVarying.value() ^ xyz);
			_fragmentCode.mov(t.value() ^ w,   	 _tangentVarying.value() ^ w  );
			_fragmentCode.nrm(b.value() ^ xyz, _bitangentVarying.value() ^ xyz);
			_fragmentCode.nrm(n.value() ^ xyz,    _normalVarying.value() ^ xyz);

			var temp : ShaderRegisterElement = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(temp, 1);
			_fragmentCode.append( _normalMethod.getFragmentCode(_normalMethodVO, _registerCache, temp));
			
			_fragmentCode.sub( temp.value() ^ xyz, temp.value() ^ xyz, _commonsReg.value() ^ x );
			_fragmentCode.nrm( temp.value() ^ xyz, temp.value() ^ xyz );
			_fragmentCode.m33( _normalFragmentReg.value() ^ xyz, temp.value() ^xyz, t.value());
			_fragmentCode.mov( _normalFragmentReg.value() ^ w,  _normalVarying.value() ^ w);

			_registerCache.removeFragmentTempUsage(temp);

			if (_normalMethodVO.needsView) _registerCache.removeFragmentTempUsage(_viewDirFragmentReg);
			if (_normalMethodVO.needsGlobalPos) _registerCache.removeVertexTempUsage(_globalPositionVertexReg);
			_registerCache.removeFragmentTempUsage(b);
			_registerCache.removeFragmentTempUsage(t);
			_registerCache.removeFragmentTempUsage(n);
		}
		
		
		/**
		 * fast and inaccurate normal mapping
		 */
/*		private function compileFastNormalMap() : void {
			
			_tangentInput = _registerCache.getFreeVertexAttribute();
			_tangentBufferIndex = _tangentInput.index;
			
			_animatedTangentReg = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_animatedTangentReg, 1);
			_animatableAttributes.push(_tangentInput.toString());
			_animationTargetRegisters.push(_animatedTangentReg.toString());
			
			_tangentVarying = _registerCache.getFreeVarying();
			_bitangentVarying = _registerCache.getFreeVarying();
			
			var temp : ShaderRegisterElement = _registerCache.getFreeVertexVectorTemp();
			
			var normalMatrix : String = "vc"+ ((_sceneNormalMatrixIndex/4 ) + _vertexConstantIndex);
			
//			_vertexCode += 	"mov " + _tangentVarying + ", " + _animatedTangentReg + " \n" +
//							"crs " + temp + ".xyz, " +_animatedNormalReg + ".xyz, " + _animatedTangentReg+".xyz \n" +
//							"mul " + _bitangentVarying + ".xyz, " +temp + ".xyz, " + _animatedTangentReg+".w \n" +
//							"mov " + _bitangentVarying + ".w, " +_animatedTangentReg+".w \n" ;
			_vertexCode += 	"m33 " + temp + ".xyz, " + _animatedTangentReg + ".xyz, "+normalMatrix+" \n" +
							"nrm " + _tangentVarying + ".xyz, " +temp+".xyz \n" +
							"crs " + temp + ".xyz, " +_normalVertexReg + ".xyz, " + temp+".xyz \n" +
							"nrm " + _bitangentVarying + ".xyz, " +temp + ".xyz \n" +
							"mov " + _bitangentVarying + ".w, " +_animatedTangentReg+".w \n" +
							"mov " + _tangentVarying + ".w, " +_animatedTangentReg+".w \n" ;
							
			_registerCache.removeVertexTempUsage(_animatedTangentReg);
		}*/

		protected function createCommons() : void
		{
			_commonsReg = _registerCache.getFreeFragmentConstant();
			_commonsDataIndex = _commonsReg.index*4;
		}

		protected function createHdr() : void
		{
			_extendedReg = _registerCache.getFreeFragmentConstant();
			_extendedDataIndex = _extendedReg.index*4;
		}


		protected function compileViewDirCode() : void
		{
			var cameraPositionReg : ShaderRegisterElement = _registerCache.getFreeVertexConstant();

			_cameraPositionIndex = (cameraPositionReg.index-_vertexConstantIndex)*4;
			
			var nrmdep : int = (( _reflectDependencies > 0 ) ? 1 : 0)+ (( _refractDependencies > 0 ) ? 1 : 0);
			if( nrmdep > 0 ) {
				_viewDirVertexReg = _registerCache.getFreeVertexVectorTemp();
				_registerCache.addVertexTempUsages( _viewDirVertexReg, nrmdep );
//				_vertexCode += "sub " + _viewDirVertexReg + ", " + cameraPositionReg + ", " + _globalPositionVertexReg + "\n";
				_vertexCode.sub( _viewDirVertexReg.value(), cameraPositionReg.value(), _globalPositionVertexReg.value() );
			} 
			
			if( _usesViewDirFragment ) {
				
				_viewDirVaryingReg = _registerCache.getFreeVarying();
				
				if( nrmdep > 0 )
//					_vertexCode += "mov " + _viewDirVaryingReg + ", " + _viewDirVertexReg + "\n";
					_vertexCode.mov( _viewDirVaryingReg.value(),  _viewDirVertexReg.value() );
				else {
//					_vertexCode += "sub " + _viewDirVaryingReg + ", " + cameraPositionReg + ", " + _globalPositionVertexReg + "\n";
					_vertexCode.sub( _viewDirVaryingReg.value(),  cameraPositionReg.value(), _globalPositionVertexReg.value() );
				}
				
				_viewDirFragmentReg = _registerCache.getFreeFragmentVectorTemp();
				_registerCache.addFragmentTempUsages( _viewDirFragmentReg, _viewDirDependencies );
//				_fragmentCode += 	"nrm " + _viewDirFragmentReg + ".xyz, " + _viewDirVaryingReg + ".xyz		\n" +
//									"mov " + _viewDirFragmentReg + ".w,   " + _viewDirVaryingReg + ".w 		\n";
									
				_fragmentCode.nrm( _viewDirFragmentReg.value() ^ xyz, _viewDirVaryingReg.value() ^ xyz );
				_fragmentCode.mov( _viewDirFragmentReg.value() ^ w,  _viewDirVaryingReg.value() ^ w);
			}

			_registerCache.removeVertexTempUsage(_globalPositionVertexReg);
		}
		
		
		protected function compileReflectCode() : void {
			
			//var refConst : ShaderRegisterElement = _registerCache.getFreeVertexConstant();
			//_reflectionConstIndex = (refConst.index-_vertexConstantIndex)*4;
			
//			var ONE : String = "vc"+(_cameraPositionIndex / 4 + _vertexConstantIndex)+".w";
			var ONE : uint = c0+(_cameraPositionIndex / 4 + _vertexConstantIndex) ^ w;
			
			_reflectVaryingReg = _registerCache.getFreeVarying();

			var temp : ShaderRegisterElement = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(temp, 1);
			var viewdir : ShaderRegisterElement = _registerCache.getFreeVertexVectorTemp();
			
			// r = I - 2(I.N)*N
			var tv : uint = temp.value();
			
			_vertexCode.nrm( viewdir.value() 	^ xyz,	_viewDirVertexReg.value() ^ xyz );
			_vertexCode.dp3(tv 		^ w,	_normalVertexReg.value()  ^ xyz, viewdir.value() ^ xyz );
			_vertexCode.sub( _reflectVaryingReg.value() ^ w, ONE ,tv ^ w );
			_vertexCode.add(tv ^ w,tv ^ w,tv ^ w );
			_vertexCode.mul(tv ^ xyz, _normalVertexReg.value() ^ xyz,tv ^ w );
			_vertexCode.sub(tv ^ xyz,tv ^ xyz, viewdir.value() ^ xyz );
			_vertexCode.nrm( _reflectVaryingReg.value() ^ xyz,tv ^ xyz	 );

			
//			_fragmentCode += 	"nrm " + _reflectFragmentReg + ".xyz, " + _reflectVaryingReg + ".xyz		\n" +
//								"mov " + _reflectFragmentReg + ".w,   " + _reflectVaryingReg + ".w 		\n";
			
			
			
			_registerCache.removeVertexTempUsage( temp );
			_registerCache.removeVertexTempUsage( _viewDirVertexReg );
			_registerCache.removeVertexTempUsage( _normalVertexReg );
		}
		
		protected function compileRefractCode() : void {
			
			var refractConstantReg : ShaderRegisterElement = _registerCache.getFreeVertexConstant();

			_refractConstantIndex = (refractConstantReg.index-_vertexConstantIndex)*4;
			
			//var ONE : String = "vc"+(_cameraPositionIndex / 4 + _vertexConstantIndex)+".w";
			var ONE : uint = c0+(_cameraPositionIndex / 4 + _vertexConstantIndex) ^ w;  
			_refractVaryingReg = _registerCache.getFreeVarying();
			
			
			var temp : ShaderRegisterElement = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(temp, 1);
			var viewdir : ShaderRegisterElement = _registerCache.getFreeVertexVectorTemp();
			
			var tv : uint = temp.value();
			
			_vertexCode.nrm(  viewdir.value() ^ xyz,_viewDirVertexReg.value() ^ xyz );
			_vertexCode.dp3(  tv ^ x, _normalVertexReg.value()  	^ xyz	, viewdir.value()^ xyz );
			_vertexCode.mul(  tv ^ w, tv 				^ x		, tv   ^ x);
			_vertexCode.sub(  tv ^ w, ONE 						, tv   ^ w);
			_vertexCode.mul(  tv ^ w, refractConstantReg.value() 	^ x		, tv   ^ w);
			_vertexCode.mul(  tv ^ w, refractConstantReg.value() 	^ x		, tv   ^ w);
			_vertexCode.sub(  tv ^ w, ONE 						, tv   ^ w);
			_vertexCode.sqt(  tv ^ y, tv 				^ w );
			_vertexCode.mul(  tv ^ x, refractConstantReg.value() 	^ x		, tv   ^ x);
			_vertexCode.add(  tv ^ x, tv 				^ x		, tv   ^ y);
			_vertexCode.mul(  _refractVaryingReg.value() 					, tv   ^ x, _normalVertexReg.value() );

			
			_registerCache.removeVertexTempUsage( temp );
			_registerCache.removeVertexTempUsage( _viewDirVertexReg );
			_registerCache.removeVertexTempUsage( _normalVertexReg );
		}
		
		

		protected function compileLightingCode() : void
		{
			var shadowReg : ShaderRegisterElement;
			var chunk : ShaderChunk;

			initLightRegisters();
			
			chunk = _diffuseMethod.getVertexCode(_diffuseMethodVO, _registerCache);
			if( chunk ) _vertexCode.append( chunk );
			chunk = _diffuseMethod.getFragmentPreLightingCode(_diffuseMethodVO, _registerCache);
			if( chunk ) _fragmentCode.append( chunk );

			if (_usingSpecularMethod) {
				chunk = _specularMethod.getVertexCode(_specularMethodVO, _registerCache);
				if( chunk ) _vertexCode.append( chunk );
				chunk = _specularMethod.getFragmentPreLightingCode(_specularMethodVO, _registerCache);
				if( chunk ) _fragmentCode.append( chunk );
			}

			_diffuseLightIndex = 0;
			_specularLightIndex = 0;

			if (_numLights > 0 && (_combinedLightSources & LightSources.LIGHTS)) {
				compileDirectionalLightCode();
				compilePointLightCode();
			}
			if (_numLightProbes > 0  && (_combinedLightSources & LightSources.PROBES))
				compileLightProbeCode();

			chunk = _ambientMethod.getVertexCode(_ambientMethodVO, _registerCache);
			if( chunk ) _vertexCode.append( chunk );
			chunk = _ambientMethod.getFragmentCode(_ambientMethodVO, _registerCache, _shadedTargetReg);
			if( chunk ) _fragmentCode.append( chunk );
			if (_ambientMethodVO.needsNormals) _registerCache.removeFragmentTempUsage(_normalFragmentReg);
			if (_ambientMethodVO.needsView) _registerCache.removeFragmentTempUsage(_viewDirFragmentReg);


			if (_shadowMethod) {
				chunk = _shadowMethod.getVertexCode(_shadowMethodVO, _registerCache);
				if( chunk ) _vertexCode.append( chunk );
				// using normal to contain shadow data if available is perhaps risky :s
				// todo: improve compilation with lifetime analysis so this isn't necessary?
				if (_normalDependencies == 0) {
					shadowReg = _registerCache.getFreeFragmentVectorTemp();
					_registerCache.addFragmentTempUsages(shadowReg, 1);
				}
				else
					shadowReg = _normalFragmentReg;

				_diffuseMethod.shadowRegister = shadowReg;
				chunk = _shadowMethod.getFragmentCode(_shadowMethodVO, _registerCache, shadowReg);
				if( chunk ) _fragmentCode.append( chunk );
			}
			chunk = _diffuseMethod.getFragmentPostLightingCode(_diffuseMethodVO, _registerCache, _shadedTargetReg);
			if( chunk ) _fragmentCode.append( chunk );

			if (_alphaPremultiplied) {
				throw new Error( "away3d.materials.passes.DefaultScreenPass - compileLightingCode : " );
//				_fragmentCode += "add " + _shadedTargetReg + ".w, " + _shadedTargetReg + ".w, " + _commonsReg + ".z\n" +
//								 "div " + _shadedTargetReg + ".xyz, " + _shadedTargetReg + ".xyz, " + _shadedTargetReg + ".w\n" +
//								 "sub " + _shadedTargetReg + ".w, " + _shadedTargetReg + ".w, " + _commonsReg + ".z\n"
//								 "sat " + _shadedTargetReg + ".xyz, " + _shadedTargetReg + ".xyz\n";
			}

			// resolve other dependencies as well?
			if (_diffuseMethodVO.needsNormals) _registerCache.removeFragmentTempUsage(_normalFragmentReg);
			if (_diffuseMethodVO.needsView) _registerCache.removeFragmentTempUsage(_viewDirFragmentReg);

			if (_usingSpecularMethod) {
				_specularMethod.shadowRegister = shadowReg;
				chunk = _specularMethod.getFragmentPostLightingCode(_specularMethodVO, _registerCache, _shadedTargetReg);
				if( chunk ) _fragmentCode.append( chunk );
				if (_specularMethodVO.needsNormals) _registerCache.removeFragmentTempUsage(_normalFragmentReg);
				if (_specularMethodVO.needsView) _registerCache.removeFragmentTempUsage(_viewDirFragmentReg);
			}
		}

		protected function initLightRegisters() : void
		{
			// init these first so we're sure they're in sequence
			var i : uint, len : uint;

			len = _dirLightRegisters.length;
			for (i = 0; i < len; ++i) {
				_dirLightRegisters[i] = _registerCache.getFreeFragmentConstant();
				if (_lightDataIndex == -1) _lightDataIndex = _dirLightRegisters[i].index*4;
			}

			len = _pointLightRegisters.length;
			for (i = 0; i < len; ++i) {
				_pointLightRegisters[i] = _registerCache.getFreeFragmentConstant();
				if (_lightDataIndex == -1) _lightDataIndex = _pointLightRegisters[i].index*4;
			}
		}

		protected function compileDirectionalLightCode() : void
		{
			var diffuseColorReg : ShaderRegisterElement;
			var specularColorReg : ShaderRegisterElement;
			var lightDirReg : ShaderRegisterElement;
			var regIndex : int;
			var addSpec : Boolean = _usingSpecularMethod && ((_specularLightSources & LightSources.LIGHTS) != 0);
			var addDiff : Boolean = (_diffuseLightSources & LightSources.LIGHTS) != 0;
			var chunk : ShaderChunk;

			if (!(addSpec || addDiff)) return;

			for (var i : uint = 0; i < _numDirectionalLights; ++i) {
				lightDirReg = _dirLightRegisters[regIndex++];
				diffuseColorReg = _dirLightRegisters[regIndex++];
				specularColorReg = _dirLightRegisters[regIndex++];
				if (addDiff) {
					chunk = _diffuseMethod.getFragmentCodePerLight(_diffuseMethodVO, _diffuseLightIndex, lightDirReg, diffuseColorReg, _registerCache);
					if( chunk ) _fragmentCode.append( chunk );
					++_diffuseLightIndex;
				}
				if (addSpec) {
					chunk = _specularMethod.getFragmentCodePerLight(_specularMethodVO, _specularLightIndex, lightDirReg, specularColorReg, _registerCache);
					if( chunk ) _fragmentCode.append( chunk );
					++_specularLightIndex;
				}

			}
		}

		protected function compilePointLightCode() : void
		{
			var diffuseColorReg : ShaderRegisterElement;
			var specularColorReg : ShaderRegisterElement;
			var lightPosReg : ShaderRegisterElement;
			var lightDirReg : ShaderRegisterElement;
			var regIndex : int;
			var addSpec : Boolean = _usingSpecularMethod && ((_specularLightSources & LightSources.LIGHTS) != 0);
			var addDiff : Boolean = (_diffuseLightSources & LightSources.LIGHTS) != 0;
			var ldr : uint = lightDirReg.value();
			var chunk : ShaderChunk;
			
			if (!(addSpec || addDiff)) return;

			for (var i : uint = 0; i < _numPointLights; ++i) {
				lightPosReg = _pointLightRegisters[regIndex++];
				diffuseColorReg = _pointLightRegisters[regIndex++];
				specularColorReg = _pointLightRegisters[regIndex++];
				lightDirReg = _registerCache.getFreeFragmentVectorTemp();
				_registerCache.addFragmentTempUsages(lightDirReg, 1);

				// calculate direction
				_fragmentCode.sub( ldr,     lightPosReg.value() , _globalPositionVaryingReg.value() );
				_fragmentCode.dp3( ldr^w,   ldr         ^ xyz, ldr ^ xyz );
				_fragmentCode.sqt( ldr^w,   ldr         ^ w );
				_fragmentCode.sub( ldr^w,   ldr         ^ w, diffuseColorReg.value() ^ w );
				_fragmentCode.mul( ldr^w,   ldr         ^ w, specularColorReg.value() ^ w );
				_fragmentCode.sat( ldr^w,   ldr         ^ w );
				_fragmentCode.sub( ldr^w,   lightPosReg.value() ^ w, ldr ^ w );
				_fragmentCode.nrm( ldr^xyz, ldr         ^ xyz	 );

				if (_lightDataIndex == -1) _lightDataIndex = lightPosReg.index*4;
				if (addDiff) {
					// TODO: vo can contain register data
					chunk = _diffuseMethod.getFragmentCodePerLight(_diffuseMethodVO, _diffuseLightIndex, lightDirReg, diffuseColorReg, _registerCache);
					if( chunk ) _fragmentCode.append( chunk );
					++_diffuseLightIndex;
				}
				if (addSpec) {
					chunk = _specularMethod.getFragmentCodePerLight(_specularMethodVO, _specularLightIndex, lightDirReg, specularColorReg, _registerCache);
					if( chunk ) _fragmentCode.append( chunk );
					++_specularLightIndex;
				}

				_registerCache.removeFragmentTempUsage(lightDirReg);
			}
		}

		protected function compileLightProbeCode() : void
		{
			var weightReg : uint;
			var weightComponents : Array = [ x, y, z, w ];
			var weightRegisters : Vector.<ShaderRegisterElement> = new Vector.<ShaderRegisterElement>();
			var i : uint;
			var texReg : ShaderRegisterElement;
			var addSpec : Boolean = _usingSpecularMethod && ((_specularLightSources & LightSources.PROBES) != 0);
			var addDiff : Boolean = (_diffuseLightSources & LightSources.PROBES) != 0;
			var chunk : ShaderChunk;
			
			if (!(addSpec || addDiff)) return;

			if (addDiff)
				_lightProbeDiffuseIndices = new Vector.<uint>();
			if (addSpec)
				_lightProbeSpecularIndices = new Vector.<uint>();

			for (i = 0; i < _numProbeRegisters; ++i) {
				weightRegisters[i] = _registerCache.getFreeFragmentConstant();
				if (i == 0) _probeWeightsIndex = weightRegisters[i].index*4;
			}

			for (i = 0; i < _numLightProbes; ++i) {
				weightReg = weightRegisters[Math.floor(i/4)].value() ^ weightComponents[i % 4];

				if (addDiff) {
					texReg = _registerCache.getFreeTextureReg();
					_lightProbeDiffuseIndices[i] = texReg.index;
					chunk = _diffuseMethod.getFragmentCodePerProbe(_diffuseMethodVO, _diffuseLightIndex, texReg, weightReg, _registerCache);
					if( chunk ) _fragmentCode.append( chunk );
					++_diffuseLightIndex;
				}

				if (addSpec) {
					texReg = _registerCache.getFreeTextureReg();
					_lightProbeSpecularIndices[i] = texReg.index;
					chunk = _specularMethod.getFragmentCodePerProbe(_specularMethodVO, _specularLightIndex, texReg, weightReg, _registerCache);
					if( chunk ) _fragmentCode.append( chunk );
					++_specularLightIndex;
				}
			}
		}

		protected function compileMethods() : void
		{
			var numMethods : uint = _methods.length;
			var method : EffectMethodBase;
			var data : MethodVO;
			var chunk : ShaderChunk;

			for (var i : uint = 0; i < numMethods; ++i) {
				method = _methods[i].method;
				data = _methods[i].data;
				chunk = method.getVertexCode(data, _registerCache);
				if( chunk ) _vertexCode.append( chunk );
				if (data.needsGlobalPos) _registerCache.removeVertexTempUsage(_globalPositionVertexReg);

				chunk = method.getFragmentCode(data, _registerCache, _shadedTargetReg);
				if( chunk ) _fragmentCode.append( chunk );
				
				if (data.needsNormals) _registerCache.removeFragmentTempUsage(_normalFragmentReg);
				if (data.needsView) _registerCache.removeFragmentTempUsage(_viewDirFragmentReg);
			}

			if (_colorTransformMethod) {
				chunk = _colorTransformMethod.getVertexCode(_colorTransformMethodVO, _registerCache);
				if( chunk ) _vertexCode.append( chunk );
				chunk = _colorTransformMethod.getFragmentCode(_colorTransformMethodVO, _registerCache, _shadedTargetReg);
				if( chunk ) _fragmentCode.append( chunk );
			}
		}

		/**
		 * Updates the lights data for the render state.
		 * @param lights The lights selected to shade the current object.
		 * @param numLights The amount of lights available.
		 * @param maxLights The maximum amount of lights supported.
		 */
		protected function updateLights(directionalLights : Vector.<DirectionalLight>, pointLights : Vector.<PointLight>, stage3DProxy : Stage3DProxy) : void
		{
			// first dirs, then points
			var dirLight : DirectionalLight;
			var pointLight : PointLight;
			var i : uint, k : uint;
			var len : int;
			var dirPos : Vector3D;

			_ambientLightR = _ambientLightG = _ambientLightB = 0;

			len = directionalLights.length;
			k = _lightDataIndex;
			for (i = 0; i < len; ++i) {
				dirLight = directionalLights[i];
				dirPos = dirLight.sceneDirection;

				_ambientLightR += dirLight._ambientR;
				_ambientLightG += dirLight._ambientG;
				_ambientLightB += dirLight._ambientB;

				_fragmentConstantData[k++] = -dirPos.x;
				_fragmentConstantData[k++] = -dirPos.y;
				_fragmentConstantData[k++] = -dirPos.z;
				_fragmentConstantData[k++] = 1;

				_fragmentConstantData[k++] = dirLight._diffuseR;
				_fragmentConstantData[k++] = dirLight._diffuseG;
				_fragmentConstantData[k++] = dirLight._diffuseB;
				_fragmentConstantData[k++] = 1;

				_fragmentConstantData[k++] = dirLight._specularR;
				_fragmentConstantData[k++] = dirLight._specularG;
				_fragmentConstantData[k++] = dirLight._specularB;
				_fragmentConstantData[k++] = 1;
			}

			// more directional supported than currently picked, need to clamp all to 0
			if (_numDirectionalLights > len) {
				i = k + (_numDirectionalLights - len) * 12;
				while (k < i)
					_fragmentConstantData[k++] = 0;
			}

			len = pointLights.length;
			for (i = 0; i < len; ++i) {
				pointLight = pointLights[i];
				dirPos = pointLight.scenePosition;

				_ambientLightR += pointLight._ambientR;
				_ambientLightG += pointLight._ambientG;
				_ambientLightB += pointLight._ambientB;

				_fragmentConstantData[k++] = dirPos.x;
				_fragmentConstantData[k++] = dirPos.y;
				_fragmentConstantData[k++] = dirPos.z;
				_fragmentConstantData[k++] = 1;

				_fragmentConstantData[k++] = pointLight._diffuseR;
				_fragmentConstantData[k++] = pointLight._diffuseG;
				_fragmentConstantData[k++] = pointLight._diffuseB;
				_fragmentConstantData[k++] = pointLight._radius;

				_fragmentConstantData[k++] = pointLight._specularR;
				_fragmentConstantData[k++] = pointLight._specularG;
				_fragmentConstantData[k++] = pointLight._specularB;
				_fragmentConstantData[k++] = pointLight._fallOffFactor;
			}

			// more directional supported than currently picked, need to clamp all to 0
			if (_numPointLights > len) {
				i = k + (len - _numPointLights) * 12;
				for (; k < i; ++k)
					_fragmentConstantData[k] = 0;
			}
		}

		protected function updateProbes(lightProbes : Vector.<LightProbe>, weights : Vector.<Number>, stage3DProxy : Stage3DProxy) : void
		{
			var probe : LightProbe;
			var len : int = lightProbes.length;
			var addDiff : Boolean = _diffuseMethod && ((_diffuseLightSources & LightSources.PROBES) != 0);
			var addSpec : Boolean = _specularMethod && ((_specularLightSources & LightSources.PROBES) != 0);

			if (!(addDiff || addSpec)) return;

			for (var i : uint = 0; i < len; ++i) {
				probe = lightProbes[i];

				if (addDiff)
					stage3DProxy.setTextureAt(_lightProbeDiffuseIndices[i], probe.diffuseMap.getTextureForStage3D(stage3DProxy));
				if (addSpec)
					stage3DProxy.setTextureAt(_lightProbeSpecularIndices[i], probe.specularMap.getTextureForStage3D(stage3DProxy));
			}

			_fragmentConstantData[_probeWeightsIndex] = weights[0];
			_fragmentConstantData[_probeWeightsIndex + 1] = weights[1];
			_fragmentConstantData[_probeWeightsIndex + 2] = weights[2];
			_fragmentConstantData[_probeWeightsIndex + 3] = weights[3];
		}

		protected function getMethodSetForMethod(method : EffectMethodBase) : MethodSet
		{
			var len : int = _methods.length;
			for (var i : int = 0; i < len; ++i)
				if (_methods[i].method == method) return _methods[i];

			return null;
		}

		protected function onShaderInvalidated(event : ShadingMethodEvent) : void
		{
			invalidateShaderProgram();
		}
	}
}
