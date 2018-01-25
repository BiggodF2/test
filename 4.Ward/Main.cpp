#include <WinApp.h>
#include <AppUtil.h>
#include <GeometryGens.h>
#include <Lights.h>
#include <d3dx11effect.h>
#include <D3DX11async.h>
#include <vector>
#include <fstream>
#include <sstream>
#include <D3Dcompiler.h>

using namespace std;

struct Vertex
{
	XMFLOAT3	pos;
	XMFLOAT3	normal;
};

class LightDemo: public WinApp
{
public:
	LightDemo(HINSTANCE hInst,std::wstring title = L"D3D11学习 光照计算", int width = 640, int height = 480);
	~LightDemo();

	bool Init();
	bool Update(float delta);
	bool Render();

	virtual void OnMouseDown(WPARAM btnState, int x, int y);
	virtual void OnMouseUp(WPARAM btnState, int x, int y);
	virtual void OnMouseMove(WPARAM btnState, int x, int y);

private:
	bool BuildFX();
	bool BuildInputLayout();
	bool BuildBuffers();

private:
	ID3D11InputLayout	*m_inputLayout;

	//顶点、索引缓冲区
	ID3D11Buffer	*m_VB;
	ID3D11Buffer	*m_IB;

	//Effect接口
	ID3DX11Effect					*m_fx;

	//Effect全局变量
	//针对每个物体
	ID3DX11EffectMatrixVariable		*m_fxWorldViewProj;
	ID3DX11EffectMatrixVariable		*m_fxWorld;
	ID3DX11EffectMatrixVariable		*m_fxWorldInvTranspose;
	ID3DX11EffectVariable			*m_fxMaterial;
	//针对每一帧
	ID3DX11EffectVariable			*m_fxLights;
	ID3DX11EffectVariable			*m_fxEyePos;

	Lights::DirLight				m_lights[3];
	Lights::SpotLight				m_spotLight;
	int								m_numLights;
	Lights::Material				m_matGrid;
	Lights::Material				m_matBox;
	Lights::Material				m_matSphere;
	Lights::Material				m_matCylinder;
	Lights::Material				m_matTopCylinder;
	XMFLOAT3						m_eyePos;

	//视角、投影矩阵
	XMFLOAT4X4	m_view;
	XMFLOAT4X4	m_proj;
	
	//几何物体
	GeoGen::MeshData	m_grid;
	GeoGen::MeshData	m_box;
	GeoGen::MeshData	m_sphere;
	GeoGen::MeshData	m_cylinder;
	GeoGen::MeshData	m_topCylinder;
	//几何物体顶点、索引位置信息
	UINT	m_gridVStart,		m_gridIStart;
	UINT	m_boxVStart,		m_boxIStart;
	UINT	m_sphereVStart,		m_sphereIStart;
	UINT	m_cylinderVStart,	m_cylinderIStart;
	UINT	m_topCylinderVSstart, m_topCylinderIStart;
	//几何物体世界变换矩阵
	XMFLOAT4X4	m_gridWorld;
	XMFLOAT4X4	m_boxWorld;
	XMFLOAT4X4	m_sphereWorld[5];
	XMFLOAT4X4	m_cylinderWorld[4];
	XMFLOAT4X4	m_topCylinderWorld[4];

	//鼠标控制参数
	POINT	m_lastPos;
	float	m_theta, m_phy;
	float	m_radius;

};

LightDemo::LightDemo(HINSTANCE hInst, std::wstring title, int width, int height):WinApp(hInst,title,width,height),
	m_inputLayout(NULL),
	m_VB(NULL),
	m_IB(NULL),
	m_fx(NULL),
	m_fxWorldViewProj(NULL),
	m_fxWorld(NULL),
	m_fxWorldInvTranspose(NULL),
	m_fxMaterial(NULL),
	m_fxLights(NULL),
	m_numLights(3),
	m_fxEyePos(NULL),
	m_theta(XM_PI*1.5f),
	m_phy(XM_PI*0.4f),
	m_radius(20.f)
{
	XMMATRIX gridWorld = XMMatrixIdentity();
	XMStoreFloat4x4(&m_gridWorld,gridWorld);
	XMMATRIX boxWorld = XMMatrixTranslation(0.f,0.75f,0.f);
	XMStoreFloat4x4(&m_boxWorld,boxWorld);
	XMMATRIX sphereWorld = XMMatrixTranslation(0.f,3.5f,0.f);
	XMStoreFloat4x4(&m_sphereWorld[4],sphereWorld);

	for(UINT i=0; i<2; ++i)
	{
		for(UINT j=0; j<2; ++j)
		{
			XMMATRIX cylinderWorld = XMMatrixTranslation(-5.f+i*10.f,1.f,-5.f+j*10.f);
			XMStoreFloat4x4(&m_cylinderWorld[i*2+j],cylinderWorld);
			XMMATRIX sphereWorld = XMMatrixTranslation(-5.f+i*10.f,4.f,-5.f+j*10.f);
			XMStoreFloat4x4(&m_sphereWorld[i*2+j],sphereWorld);
			XMMATRIX topCylinderWorld = XMMatrixTranslation(-5.f+i*10.f,4.f,-5.f+j*10.f);
			XMStoreFloat4x4(&m_topCylinderWorld[i*2+j],topCylinderWorld);
		}
	}

	//"三点式"照明
	//主光源
	m_lights[0].ambient  =	XMFLOAT4(0.2f, 0.2f, 0.2f, 1.0f);
	m_lights[0].diffuse  =	XMFLOAT4(0.5f, 0.5f, 0.5f, 1.0f);
	m_lights[0].specular =	XMFLOAT4(0.5f, 0.5f, 0.5f, 1.0f);
	m_lights[0].dir		 =	XMFLOAT3(0.5f, 0.57735f, 0.f);
	//侧光源
	m_lights[1].ambient  =	XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f);
	m_lights[1].diffuse  =	XMFLOAT4(0.20f, 0.20f, 0.20f, 1.0f);
	m_lights[1].specular =	XMFLOAT4(0.25f, 0.25f, 0.25f, 1.0f);
	m_lights[1].dir		 =	XMFLOAT3(-0.57735f, -0.57735f, 0.57735f);
	//背光源
	m_lights[2].ambient  =	XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f);
	m_lights[2].diffuse  =	XMFLOAT4(0.2f, 0.2f, 0.2f, 1.0f);
	m_lights[2].specular =	XMFLOAT4(0.0f, 0.0f, 0.0f, 1.0f);
	m_lights[2].dir	     =	XMFLOAT3(0.0f, -0.707f, -0.707f);
	//聚光灯
	m_spotLight.ambient = XMFLOAT4(0.f,0.f,0.f,1.f);
	m_spotLight.diffuse = XMFLOAT4(0.5f,0.5f,0.5f,1.f);
	m_spotLight.specular = XMFLOAT4(0.3f,0.3f,0.3f,1.f);
	m_spotLight.pos = XMFLOAT3(0.f,20.f,0.f);
	m_spotLight.pos = XMFLOAT3(10.f, 10.f,10.f);
	m_spotLight.range = 100.f;
	m_spotLight.theta = XMConvertToRadians(30.f);
	XMStoreFloat3(&m_spotLight.dir,
		XMVector3Normalize(XMVectorSet(-m_radius*sin(m_phy)*cos(m_theta),
		-m_radius*cos(m_phy),
		-m_radius*sin(m_phy)*sin(m_theta),0.f)));
	m_spotLight.att = XMFLOAT3(0.2f,0.f,0.f);
	m_spotLight.spot =60.f;

	//材质
	/*m_matGrid.ambient  = XMFLOAT4(0.3f, 0.3f, 0.3f, 1.0f);
	m_matGrid.diffuse  = XMFLOAT4(0.1f, 0.1f, 0.1f, 1.0f);
	m_matGrid.specular = XMFLOAT4(0.972f, 0.960f, 0.915f, 16.0f);*/

	//m_matBox.ambient  = XMFLOAT4(0.3f, 0.3f, 0.3f, 1.0f);
	//m_matBox.diffuse  = XMFLOAT4(0.1f, 0.1f, 0.1f, 1.0f);
	//m_matBox.specular = XMFLOAT4(0.972f, 0.960f, 0.915f, 16.0f);

	/*m_matSphere.ambient  = XMFLOAT4(0.3f, 0.3f, 0.3f, 1.0f);
	m_matSphere.diffuse  = XMFLOAT4(0.f, 0.f, 0.f, 1.0f);
	m_matSphere.specular = XMFLOAT4(0.972f, 0.960f, 0.915f, 16.0f);

	m_matCylinder.ambient  = XMFLOAT4(0.3f, 0.3f, 0.3f, 1.0f);
	m_matCylinder.diffuse  = XMFLOAT4(0.1f, 0.1f, 0.1f, 1.0f);
	m_matCylinder.specular = XMFLOAT4(0.972f, 0.960f, 0.915f, 16.0f);*/

	m_matTopCylinder.ambient  = XMFLOAT4(0.3f, 0.3f, 0.3f, 1.0f);
	m_matTopCylinder.diffuse  = XMFLOAT4(0.1f, 0.1f, 0.1f, 1.0f);
	m_matTopCylinder.specular = XMFLOAT4(0.972f, 0.960f, 0.915f, 16.0f);
	
	m_matGrid.ambient  = XMFLOAT4(0.48f, 0.77f, 0.46f, 1.0f);
	m_matGrid.diffuse  = XMFLOAT4(0.48f, 0.77f, 0.46f, 1.0f);
	m_matGrid.specular = XMFLOAT4(0.2f, 0.2f, 0.2f, 16.0f);
	
	m_matBox.ambient  = XMFLOAT4(0.3f, 0.3f, 0.3f, 1.0f);
	m_matBox.diffuse  = XMFLOAT4(0.1f, 0.1f, 0.1f, 1.0f);
	m_matBox.specular = XMFLOAT4(0.972f, 0.960f, 0.915f, 16.0f);

	m_matSphere.ambient  =  XMFLOAT4(0.48f, 0.77f, 0.46f, 1.0f);
	m_matSphere.diffuse  = XMFLOAT4(0.48f, 0.77f, 0.46f, 1.0f);
	m_matSphere.specular = XMFLOAT4(0.2f, 0.2f, 0.2f, 16.0f);

	m_matCylinder.ambient  = XMFLOAT4(0.651f, 0.5f, 0.392f, 1.0f);
	m_matCylinder.diffuse  = XMFLOAT4(0.651f, 0.5f, 0.392f, 1.0f);
	m_matCylinder.specular = XMFLOAT4(0.2f, 0.2f, 0.2f, 16.0f);
}

LightDemo::~LightDemo()
{
	SafeRelease(m_inputLayout);
	SafeRelease(m_fx);
	SafeRelease(m_IB);
	SafeRelease(m_VB);
}

bool LightDemo::Init()
{
	if(!WinApp::Init())
		return false;

	if(!BuildFX())
		return false;

	if(!BuildInputLayout())
		return false;

	if(!BuildBuffers())
		return false;

	return true;
}

bool LightDemo::Update(float delta)
{
	if(KeyDown('1'))
		m_numLights = 1;
	else if(KeyDown('2'))
		m_numLights = 2;
	else if(KeyDown('3'))
		m_numLights = 3;
	m_fxLights->SetRawValue((void*)&m_lights,0,sizeof(m_lights));

	XMVECTOR pos = XMVectorSet(m_radius*sin(m_phy)*cos(m_theta),m_radius*cos(m_phy),m_radius*sin(m_phy)*sin(m_theta),1.f);
	XMVECTOR target = XMVectorSet(0.f,0.f,0.f,1.f);
	XMVECTOR up = XMVectorSet(0.f,1.f,0.f,0.f);
	XMMATRIX view = XMMatrixLookAtLH(pos,target,up);
	XMStoreFloat4x4(&m_view,view);
	//保存观察点
	XMStoreFloat3(&m_eyePos,pos);
	m_fxEyePos->SetRawValue((void*)&m_eyePos,0,sizeof(m_eyePos));

	XMMATRIX proj = XMMatrixPerspectiveFovLH(XM_PI*0.25f,1.f*m_clientWidth/m_clientHeight,1.f,1000.f);
	XMStoreFloat4x4(&m_proj,proj);

	return true;
}

bool LightDemo::Render()
{
	m_deviceContext->ClearDepthStencilView(m_depthStencilView,D3D11_CLEAR_DEPTH|D3D11_CLEAR_STENCIL,1.f,0);
	m_deviceContext->ClearRenderTargetView(m_renderTargetView,reinterpret_cast<const float*>(&Colors::Silver));
	m_deviceContext->IASetInputLayout(m_inputLayout);
	
	UINT stride = sizeof(Vertex);
	UINT offset = 0;
	m_deviceContext->IASetVertexBuffers(0,1,&m_VB,&stride,&offset);
	m_deviceContext->IASetIndexBuffer(m_IB,DXGI_FORMAT_R32_UINT,0);
	m_deviceContext->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

	XMMATRIX view = XMLoadFloat4x4(&m_view);
	XMMATRIX proj = XMLoadFloat4x4(&m_proj);

	ostringstream tmp;
	tmp<<"Light"<<m_numLights;
	string techName = tmp.str().c_str();
	ID3DX11EffectTechnique *tech = m_fx->GetTechniqueByName(techName.c_str());
	D3DX11_TECHNIQUE_DESC techDesc;
	tech->GetDesc(&techDesc);

	XMMATRIX world = XMLoadFloat4x4(&m_gridWorld);
	//设置世界变换矩阵
	m_fxWorld->SetMatrix(reinterpret_cast<float*>(&world));
	//设置投影变换矩阵
	m_fxWorldViewProj->SetMatrix(reinterpret_cast<float*>(&(world*view*proj)));
	//设置材质
	m_fxMaterial->SetRawValue((void*)&m_matGrid,0,sizeof(m_matGrid));
	XMVECTOR det = XMMatrixDeterminant(world);
	XMMATRIX worldInvTranspose = XMMatrixTranspose(XMMatrixInverse(&det,world));
	//设置世界+反+转置矩阵
	m_fxWorldInvTranspose->SetMatrix(reinterpret_cast<float*>(&world));
	//绘制网格
	for(UINT i=0; i<techDesc.Passes; ++i)
	{
		tech->GetPassByIndex(i)->Apply(0,m_deviceContext);
		m_deviceContext->DrawIndexed(m_grid.indices.size(),m_gridIStart,m_gridVStart);
	}

	world = XMLoadFloat4x4(&m_boxWorld);
	//设置世界变换矩阵
	m_fxWorld->SetMatrix(reinterpret_cast<float*>(&world));
	//设置变换矩阵
	m_fxWorldViewProj->SetMatrix(reinterpret_cast<float*>(&(world*view*proj)));
	//设置材质
	m_fxMaterial->SetRawValue(&m_matBox,0,sizeof(m_matBox));
	det = XMMatrixDeterminant(world);
	worldInvTranspose = XMMatrixTranspose(XMMatrixInverse(&det,world));
	//设置世界+反+转置矩阵
	m_fxWorldInvTranspose->SetMatrix(reinterpret_cast<float*>(&worldInvTranspose));
	//绘制立方体
	for(UINT i=0; i<techDesc.Passes; ++i)
	{
		tech->GetPassByIndex(i)->Apply(0,m_deviceContext);
		m_deviceContext->DrawIndexed(m_box.indices.size(),m_boxIStart,m_boxVStart);
	}
	
	world = XMLoadFloat4x4(&m_sphereWorld[4]);
	//设置世界变换矩阵
	m_fxWorld->SetMatrix(reinterpret_cast<float*>(&world));
	//设置投影变换矩阵
	m_fxWorldViewProj->SetMatrix(reinterpret_cast<float*>(&(world*view*proj)));
	//设置材质
	m_fxMaterial->SetRawValue(&m_matSphere,0,sizeof(m_matSphere));
	det = XMMatrixDeterminant(world);
	worldInvTranspose = XMMatrixTranspose(XMMatrixInverse(&det,world));
	//设置世界+反+转置矩阵
	m_fxWorldInvTranspose->SetMatrix(reinterpret_cast<float*>(&worldInvTranspose));
	//绘制中心的球
	for(UINT i=0; i<techDesc.Passes; ++i)
	{
		tech->GetPassByIndex(i)->Apply(0,m_deviceContext);
		m_deviceContext->DrawIndexed(m_sphere.indices.size(),m_sphereIStart,m_sphereVStart);
	}
	
	for(UINT i=0; i<4; ++i)
	{
		world = XMLoadFloat4x4(&m_cylinderWorld[i]);
		//设置世界变换矩阵
		m_fxWorld->SetMatrix(reinterpret_cast<float*>(&world));
		//设置投影变换矩阵
		m_fxWorldViewProj->SetMatrix(reinterpret_cast<float*>(&(world*view*proj)));
		//设置材质
		m_fxMaterial->SetRawValue(&m_matCylinder,0,sizeof(m_matCylinder));
		det = XMMatrixDeterminant(world);
		worldInvTranspose = XMMatrixTranspose(XMMatrixInverse(&det,world));
		//设置世界+反+转置矩阵
		m_fxWorldInvTranspose->SetMatrix(reinterpret_cast<float*>(&worldInvTranspose));
		for(UINT j=0; j<techDesc.Passes; ++j)
		{
			tech->GetPassByIndex(j)->Apply(0,m_deviceContext);
			m_deviceContext->DrawIndexed(m_cylinder.indices.size(),m_cylinderIStart,m_cylinderVStart);
		}

		world = XMLoadFloat4x4(&m_topCylinderWorld[i]);
		//设置世界变换矩阵
		m_fxWorld->SetMatrix(reinterpret_cast<float*>(&world));
		//设置投影变换矩阵
		m_fxWorldViewProj->SetMatrix(reinterpret_cast<float	*>(&(world*view*proj)));
		//设置材质
		m_fxMaterial->SetRawValue(&m_matTopCylinder,0,sizeof(m_matTopCylinder));
		det = XMMatrixDeterminant(world);
		worldInvTranspose = XMMatrixTranspose(XMMatrixInverse(&det,world));
		//设置世界+反+转置矩阵
		m_fxWorldInvTranspose->SetMatrix(reinterpret_cast<float*>(&worldInvTranspose));
		for (UINT j = 0;j < techDesc.Passes; ++j)
		{
			tech->GetPassByIndex(j)->Apply(0, m_deviceContext);
			m_deviceContext->DrawIndexed(m_topCylinder.indices.size(),m_topCylinderIStart,m_topCylinderVSstart);
		}

		world = XMLoadFloat4x4(&m_sphereWorld[i]);
		//设置世界变换矩阵
		m_fxWorld->SetMatrix(reinterpret_cast<float*>(&world));
		//设置投影变换矩阵
		m_fxWorldViewProj->SetMatrix(reinterpret_cast<float*>(&(world*view*proj)));
		//设置材质
		m_fxMaterial->SetRawValue(&m_matSphere,0,sizeof(m_matSphere));
		det = XMMatrixDeterminant(world);
		worldInvTranspose = XMMatrixTranspose(XMMatrixInverse(&det,world));
		//设置世界+反+转置矩阵
		m_fxWorldInvTranspose->SetMatrix(reinterpret_cast<float*>(&worldInvTranspose));
		for(UINT j=0; j<techDesc.Passes; ++j)
		{
			tech->GetPassByIndex(j)->Apply(0,m_deviceContext);
			m_deviceContext->DrawIndexed(m_sphere.indices.size(),m_sphereIStart,m_sphereVStart);
		}
	}

	m_swapChain->Present(0,0);
	return true;
}

void LightDemo::OnMouseDown(WPARAM btnState, int x, int y)
{
	m_lastPos.x = x;
	m_lastPos.y = y;

	SetCapture(m_hWnd);
}

void LightDemo::OnMouseUp(WPARAM btnState, int x, int y)
{
	ReleaseCapture();
}

void LightDemo::OnMouseMove(WPARAM btnState, int x, int y)
{
	if((btnState & MK_LBUTTON) != 0)
	{
		float dx = XMConvertToRadians(0.25f*(x - m_lastPos.x));
		float dy = XMConvertToRadians(0.25f*(y - m_lastPos.y));

		m_theta -= dx;
		m_phy -= dy;

		m_phy = Clamp(0.01f,XM_PI-0.01f,m_phy);		
	}
	else if((btnState & MK_RBUTTON) != 0)
	{
		float dRadius = 0.01f * static_cast<float>(x - m_lastPos.x);
		m_radius -= dRadius;

		m_radius = Clamp(3.f,300.f,m_radius);
	}

	m_lastPos.x = x;
	m_lastPos.y = y;
}

bool LightDemo::BuildFX()
{
	/*ifstream fxFile("FX/BasicLight.fxo",ios::binary);
	if(!fxFile)
	{
		return false;
	}

	fxFile.seekg(0,ifstream::end);
	UINT size = static_cast<UINT>(fxFile.tellg());
	fxFile.seekg(0,ifstream::beg);

	vector<char> shader(size);
	fxFile.read(&shader[0],size);

	fxFile.close();

	if(FAILED(D3DX11CreateEffectFromMemory(&shader[0],size,0,m_d3dDevice,&m_fx)))
	{
		MessageBox(NULL,L"CreateEffect failed!",L"Error",MB_OK);
		return false;
	}*/
	ID3D10Blob  *shader(NULL);  
	ID3D10Blob  *errMsg(NULL);  
	//编译effect  
	HRESULT hr = D3DX11CompileFromFile(L"FX/BasicLight.fx",0,0,0,"fx_5_0",D3DCOMPILE_DEBUG,0,0,&shader,&errMsg,0);  
	//如果有编译错误，显示之  
	/*if(errMsg)  
	{  
		MessageBoxA(NULL,(char*)errMsg->GetBufferPointer(),"ShaderCompileError",MB_OK);  
		errMsg->Release();  
		return FALSE;	
	}  
	if(FAILED(hr))  
	{  
		MessageBox(NULL,L"CompileShader错误!",L"错误",MB_OK);  
		return FALSE;  
	} */


    HRESULT d3dResult;
    d3dResult = D3DX11CreateEffectFromMemory( shader->GetBufferPointer( ),
        shader->GetBufferSize( ), 0, m_d3dDevice, &m_fx );
    if( FAILED( d3dResult ) )
    {
      
        return false;
    }

	m_fxWorldViewProj = m_fx->GetVariableByName("g_worldViewProj")->AsMatrix();
	m_fxWorld = m_fx->GetVariableByName("g_world")->AsMatrix();
	m_fxWorldInvTranspose = m_fx->GetVariableByName("g_worldInvTranspose")->AsMatrix();
	m_fxLights = m_fx->GetVariableByName("g_lights");
	m_fxMaterial = m_fx->GetVariableByName("g_material");
	m_fxEyePos = m_fx->GetVariableByName("g_eyePos");

	return true;
}
bool LightDemo::BuildInputLayout()
{
	D3D11_INPUT_ELEMENT_DESC iDesc[2] = 
	{
		{"POSITION",0,DXGI_FORMAT_R32G32B32_FLOAT,0,0, D3D11_INPUT_PER_VERTEX_DATA,0},
		{"NORMAL",  0,DXGI_FORMAT_R32G32B32_FLOAT,0,12,D3D11_INPUT_PER_VERTEX_DATA,0}
	};

	ID3DX11EffectTechnique *tech = m_fx->GetTechniqueByName("Light1");
	D3DX11_PASS_DESC pDesc;
	tech->GetPassByIndex(0)->GetDesc(&pDesc);
	if(FAILED(m_d3dDevice->CreateInputLayout(iDesc,2,pDesc.pIAInputSignature,pDesc.IAInputSignatureSize,&m_inputLayout)))
	{
		MessageBox(NULL,L"CreateInputLayout failed!",L"Error",MB_OK);
		return false;
	}

	return true;
}

bool LightDemo::BuildBuffers()
{
	GeoGen::CreateGrid(20.f,20.f,50,50,m_grid);
	GeoGen::CreateBox(2,1.5f,2,m_box);
	GeoGen::CreateSphere(2,40,30,m_sphere);
	GeoGen::CreateCylinder(2.5f,2.5f,2,30,20,m_cylinder);
	GeoGen::AddCylinderTopCap(2.5f,2.5f,2,30,20,m_cylinder);

	m_gridVStart = 0;											m_gridIStart = 0;
	m_boxVStart = m_grid.vertices.size();						m_boxIStart = m_grid.indices.size();
	m_sphereVStart = m_boxVStart+m_box.vertices.size();			m_sphereIStart = m_boxIStart+m_box.indices.size();
	m_cylinderVStart = m_sphereVStart+m_sphere.vertices.size();	m_cylinderIStart = m_sphereIStart+m_sphere.indices.size();
	

	UINT totalVerts = m_cylinderVStart + m_cylinder.vertices.size();
	UINT totalIndices = m_cylinderIStart + m_cylinder.indices.size();

	vector<Vertex> vertices(totalVerts);
	for(UINT i=0; i<m_grid.vertices.size(); ++i)
	{
		vertices[m_gridVStart+i].pos = m_grid.vertices[i].pos;
		vertices[m_gridVStart+i].normal = m_grid.vertices[i].normal;
	}
	for(UINT i=0; i<m_box.vertices.size(); ++i)
	{
		vertices[m_boxVStart+i].pos = m_box.vertices[i].pos;
		vertices[m_boxVStart+i].normal = m_box.vertices[i].normal;
	}
	for(UINT i=0; i<m_sphere.vertices.size(); ++i)
	{
		vertices[m_sphereVStart+i].pos = m_sphere.vertices[i].pos;
		vertices[m_sphereVStart+i].normal = m_sphere.vertices[i].normal;
	}
	for(UINT i=0; i<m_cylinder.vertices.size(); ++i)
	{
		vertices[m_cylinderVStart+i].pos = m_cylinder.vertices[i].pos;
		vertices[m_cylinderVStart+i].normal = m_cylinder.vertices[i].normal;
	}

	D3D11_BUFFER_DESC vbDesc = {0};
	vbDesc.ByteWidth = totalVerts * sizeof(Vertex);
	vbDesc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
	vbDesc.CPUAccessFlags = 0;
	vbDesc.MiscFlags = 0;
	vbDesc.StructureByteStride = 0;
	vbDesc.Usage = D3D11_USAGE_IMMUTABLE;

	D3D11_SUBRESOURCE_DATA vbData;
	vbData.pSysMem = &vertices[0];
	vbData.SysMemPitch = 0;
	vbData.SysMemSlicePitch = 0;

	if(FAILED(m_d3dDevice->CreateBuffer(&vbDesc,&vbData,&m_VB)))
	{
		MessageBox(NULL,L"CreateVertexBuffer failed!",L"Error",MB_OK);
		return false;
	}

	vector<UINT> indices(totalIndices);
	for(UINT i=0; i<m_grid.indices.size(); ++i)
	{
		indices[m_gridIStart+i] = m_grid.indices[i];
	}
	for(UINT i=0; i<m_box.indices.size(); ++i)
	{
		indices[m_boxIStart+i] = m_box.indices[i];
	}
	for(UINT i=0; i<m_sphere.indices.size(); ++i)
	{
		indices[m_sphereIStart+i] = m_sphere.indices[i];
	}
	for(UINT i=0; i<m_cylinder.indices.size(); ++i)
	{
		indices[m_cylinderIStart+i] = m_cylinder.indices[i];
	}

	D3D11_BUFFER_DESC ibDesc = {0};
	ibDesc.ByteWidth = totalIndices * sizeof(UINT);
	ibDesc.BindFlags = D3D11_BIND_INDEX_BUFFER;
	ibDesc.CPUAccessFlags = 0;
	ibDesc.MiscFlags = 0;
	ibDesc.StructureByteStride = 0;
	ibDesc.Usage = D3D11_USAGE_IMMUTABLE;

	D3D11_SUBRESOURCE_DATA ibData;
	ibData.pSysMem = &indices[0];
	ibData.SysMemPitch = 0;
	ibData.SysMemSlicePitch = 0;

	if(FAILED(m_d3dDevice->CreateBuffer(&ibDesc,&ibData,&m_IB)))
	{
		MessageBox(NULL,L"CreateIndexBuffer failed!",L"Error",MB_OK);
		return false;
	}

	return true;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR cmdLine, int cmdShow)
{
#if defined(DEBUG) || defined(_DEBUG)
	_CrtSetDbgFlag( _CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF );
#endif

	LightDemo ld(hInstance);
	if(!ld.Init())
		return -1;

	return ld.Run();
}