
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


void PhongDirectionalLight(Material mat,
							 DirLight L,  
							float3 normal,
							float3 toEye,//"����->��"����  
							out float4 ambient,
							out float4 diffuse,
							out float4 specular)  
{  
    //��ʼ��  
    ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);  
    diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);  
    specular = float4(0.0f, 0.0f, 0.0f, 0.0f);  
  
    //���շ������Դ�����෴  
    float3 lightVec = normalize(-L.dir);  
  
    //����������ֵ  
    ambient = mat.ambient*L.ambient;  
  
    //����������;��淴�䣬����������ṩ����  
    //�������䣬ע����������һ��  
    diffuse = max(dot(lightVec, normal), 0) * mat.diffuse * L.diffuse;;  
  
    //Phong ����ģ����Ⱦ  
    float3 v = reflect(-lightVec, normal);  
    float specFactor = pow(max(dot(v, toEye), 0.0f), mat.specular.w);  
    specular = specFactor * mat.specular * L.specular;  
  
} 