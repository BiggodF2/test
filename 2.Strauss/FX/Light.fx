
//ƽ�й�
struct DirLight
{
	float4	ambient;	//������
	float4	diffuse;	//�������
	float4	specular;	//�߹�

	float3	dir;		//����
	float	unused;		//��4D������������
};

//���Դ
struct PointLight
{
	float4	ambient;	//������
	float4	diffuse;	//�������
	float4	specular;	//�߹�

	float3	pos;		//��Դλ��
	float	range;		//��Դ���䷶Χ

	float3	att;		//��ǿ˥��ϵ��
	float	unused;		//"4D����"������
};

//�۹��
struct SpotLight
{
	float4	ambient;	//������
	float4	diffuse;	//�������
	float4	specular;	//�߹�

	float3	dir;		//����
	float	range;		//���䷶Χ

	float3	pos;		//λ��
	float	spot;		//�۹�ǿ��ϵ��

	float3	att;		//���ϵ��
	float	theta;		//���ɢ�Ƕ�
};

//����
struct Material
{
	float4	ambient;
	float4	diffuse;
	float4	specular;	//specular�е�4��Ԫ�ش�����ʵı���⻬�̶�
};

void  StraussDirctionLight(  Material mat,
				DirLight L,
				float3	position,//����λ��
				float3	normal,
				float3	toEye,//"����->��"����,
				out 	float4 ambient,
				out		float4 diffuse,
				out		float4 specular)
{
	//��ʼ��  
    ambient  = float4(0.f,0.f,0.f,0.f);
	diffuse  = float4(0.f,0.f,0.f,0.f);
	specular = float4(0.f,0.f,0.f,0.f);

	float fSmoothness = 0.6;
	float fMetalness = 0.2;
	float fTransparency = 0.1;
	float3 n = normalize(normal);
	float3 l = normalize(L.dir);
	float3 v = normalize(toEye);
	float3 h = reflect(l, n);
	float Kf = 1.12;
	float Ks = 1.01;
	float NdotL = dot(n,l);
	float NdotV = dot(n, v);
	float HdotV = dot(h, v);
	float fNdotL = (1.0/pow(NdotL-Kf, 2.0) - 1.0/(Kf*Kf))
		/(1.0/pow(1.0-Kf,2.0)-1.0/(Kf*Kf));
	float s_cubed = pow(fSmoothness,3.0);

	float d  = ( 1.0f - fMetalness * fSmoothness ); 
	float Rd = (1.0f - s_cubed)*(1.0f - fTransparency);
	diffuse.xyz = NdotL * d * Rd * mat.diffuse.xyz;

	float r = (1.0f - fTransparency)-Rd;
	float j = fNdotL 
		* (1.0/pow(1.0-Ks,2.0) - 1.0/pow(NdotL-Ks,2.0))/(1.0/pow(1.0-Ks,2.0)-1.0/(Ks*Ks))
		* (1.0/pow(1.0-Ks,2.0) - 1.0/pow(NdotL-Ks,2.0))/(1.0/pow(1.0-Ks,2.0)-1.0/(Ks*Ks));

	// 'k' is used to provide small off-specular
	// peak for very rough surfaces. Can be changed  to suit desired results... 
	const float k = 0.1f;
	float reflect = min(1.0f, r + j * (r + k));

	float3 C1 = float3(1.0f, 1.0f, 1.0f);
	float3 Cs = C1 + fMetalness * (1.0f - fNdotL) * (mat.diffuse.xyz-C1);

	specular.xyz = Cs * reflect * pow(-HdotV, 3.0/(1.0f - fSmoothness));

	diffuse.xyz = max(0.0f, diffuse);
	specular.xyz = max(0.0f, specular);
	diffuse.w = 1.0f;
	specular.w = 1.0f;
	ambient = mat.ambient * L.ambient;

}
