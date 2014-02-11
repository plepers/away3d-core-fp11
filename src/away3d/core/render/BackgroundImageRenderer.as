package away3d.core.render {

	import away3d.core.managers.Stage3DProxy;
	import away3d.textures.Texture2DBase;

	import com.instagal.Shader;
	import com.instagal.Tex;
	import com.instagal.regs.*;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class BackgroundImageRenderer
	{
		protected var _program3d : Program3D;
		protected var _texture : Texture2DBase;
		protected var _indexBuffer : IndexBuffer3D;
		protected var _vertexBuffer : VertexBuffer3D;
		protected var _stage3DProxy : Stage3DProxy;
		protected var _rttData : Vector.<Number>;
		protected var _programInvalid : Boolean;
		
		
		private static const _vprg : ByteArray = new ByteArray();
		private static const _fprg : ByteArray = new ByteArray();


		public function BackgroundImageRenderer(stage3DProxy : Stage3DProxy)
		{
			this.stage3DProxy = stage3DProxy;
			_rttData = new <Number>[1, 1, 1, 1];
		}

		public function get stage3DProxy() : Stage3DProxy
		{
			return _stage3DProxy;
		}

		public function set stage3DProxy(value : Stage3DProxy) : void
		{
			if (value == _stage3DProxy) return;
			_stage3DProxy = value;

			if (_vertexBuffer) {
				_vertexBuffer.dispose();
				_vertexBuffer = null;
				_program3d.dispose();
				_program3d = null;
				_indexBuffer.dispose();
				_indexBuffer = null;
			}
		}

		protected function getVertexCode() : Shader
		{
			var sh : Shader = new Shader( Context3DProgramType.VERTEX );
			
			sh.mul( op, a0, c4 );
			sh.mov( v0, a1 );
			
			return sh;			
		}

		protected function getFragmentCode() : Shader
		{
			var sh : Shader = new Shader( Context3DProgramType.FRAGMENT );
			sh.tex( t0, v0, s0 | Tex.NEAREST | _texture.samplerType );
			sh.mov( oc, t0 );
			return sh;
		}

		public function dispose() : void
		{
			if (_vertexBuffer) _vertexBuffer.dispose();
			if (_program3d) _program3d.dispose();
		}

		public function render( textureRatioX : Number = 1, textureRatioY :  Number = 1) : void
		{
			var context : Context3D = _stage3DProxy.context3D;

			if (!context) return;

			if (!_vertexBuffer) initBuffers(context);
			if( !_program3d || _programInvalid ) initProgram(context);
			
			
			context.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );

			_stage3DProxy.setProgram(_program3d);
			
			for (var i : uint = 2; i < 8; ++i) {
				_stage3DProxy.setSimpleVertexBuffer(i, null, null, 0);
				_stage3DProxy.setTextureAt(i, null);
			}
			_stage3DProxy.setTextureAt(1, null);
			
			_rttData[0] = textureRatioX;
			_rttData[1] = textureRatioY;
			_stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _rttData, 1);
			
			_stage3DProxy.setTextureAt(0, _texture.getTextureForStage3D(_stage3DProxy));
			context.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			context.drawTriangles(_indexBuffer, 0, 2);
			_stage3DProxy.setSimpleVertexBuffer(0, null, null, 0);
			_stage3DProxy.setSimpleVertexBuffer(1, null, null, 0);
			_stage3DProxy.setTextureAt(0, null);
		}

		protected function initBuffers(context : Context3D) : void
		{
			_vertexBuffer = context.createVertexBuffer(4, 4);
			_indexBuffer = context.createIndexBuffer(6);
			_indexBuffer.uploadFromVector(Vector.<uint>([2, 1, 0, 3, 2, 0]), 0, 6);

			_vertexBuffer.uploadFromVector(Vector.<Number>([	-1, -1, 0, 1,
																1, -1, 1, 1,
																1,  1, 1, 0,
																-1,  1, 0, 0
															]), 0, 4);
		}

		protected function initProgram( context : Context3D ) : void {
			_vprg.endian = Endian.LITTLE_ENDIAN;
			_fprg.endian = Endian.LITTLE_ENDIAN;
			
			getVertexCode().writeBytes(_vprg );
			getFragmentCode().writeBytes(_fprg );
			
			_program3d = context.createProgram();
			_program3d.upload(	_vprg, _fprg );
			_programInvalid = false;
		}


		public function get texture() : Texture2DBase
		{
			return _texture;
		}

		public function set texture(value : Texture2DBase) : void
		{
			if( _texture == value ) return;
			_texture = value;
			_programInvalid = true;
		}
	}
}
