package away3d.materials.passes {

	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.lightpickers.LightPickerBase;
	import away3d.textures.Texture2DBase;

	import com.instagal.Shader;
	import com.instagal.ShaderChunk;
	import com.instagal.Tex;
	import com.instagal.regs.*;

	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;

	use namespace arcane;

	public class DepthMapPass extends MaterialPassBase
	{
		private var _data : Vector.<Number>;
		private var _alphaThreshold : Number = 0;
		private var _alphaMask : Texture2DBase;

		public function DepthMapPass()
		{
			super();
			_data = Vector.<Number>([	1.0, 255.0, 65025.0, 16581375.0,
										1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0,
										0.0, 0.0, 0.0, 0.0]);
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
			_data[8] = _alphaThreshold;
		}

		public function get alphaMask() : Texture2DBase
		{
			return _alphaMask;
		}

		public function set alphaMask(value : Texture2DBase) : void
		{
			_alphaMask = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode(code:ShaderChunk) : Shader
		{
			var sh : Shader = new Shader( Context3DProgramType.VERTEX );
			sh.append( code );

			// project
			sh.m44( t1, t0, c0	);
			sh.mul( op, t1, c4 );

			if (_alphaThreshold > 0) {
				_numUsedTextures = 1;
				_numUsedStreams = 2;
				sh.mov( v0, t1 );
				sh.mov( v1, a1 );

			}
			else {
				_numUsedTextures = 0;
				_numUsedStreams = 1;
				sh.mov( v0, t1 );
			}
			return sh;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : Shader
		{
			var wrap : uint = _repeat ? Tex.WRAP : Tex.CLAMP;
			var filter : uint;

			if (_smooth) filter = _mipmap ? Tex.LINEAR|Tex.MIPLINEAR : Tex.LINEAR;
			else filter = _mipmap ? Tex.NEAREST|Tex.MIPNEAREST:Tex.NEAREST;

			var code : Shader = new Shader( Context3DProgramType.FRAGMENT );
			code.div( t2, v0, v0^w		);
			code.mul( t0, c0, t2^z	);
			code.frc( t0, t0			);
			code.mul( t1, t0^yzw, c1);

			if (_alphaThreshold > 0) {
				code.tex( t3, v1, s0 | filter | wrap );
				code.sub( t3^w, t3^w, c2^x);
				code.kil( t3^w );
			}

			code.sub( oc, t0, t1 );

			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D, lightPicker : LightPickerBase) : void
		{
			if (_alphaThreshold > 0)
				stage3DProxy.setSimpleVertexBuffer(1, renderable.getUVBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_2, renderable.UVBufferOffset);

			super.render(renderable, stage3DProxy, camera, lightPicker);
		}

		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy : Stage3DProxy, camera : Camera3D, textureRatioX : Number, textureRatioY : Number) : void
		{
			super.activate(stage3DProxy, camera, textureRatioX, textureRatioY);

			if (_alphaThreshold > 0) {
				stage3DProxy.setTextureAt(0, _alphaMask.getTextureForStage3D(stage3DProxy));
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 3);
			}
			else {
				stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 2);
			}
		}
	}
}